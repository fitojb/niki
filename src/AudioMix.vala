/*
* Copyright (c) {2019} torikulhabib (https://github.com/torikulhabib)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: torikulhabib <torik.habib@Gmail.com>
*/

namespace niki {
    public class AudioMix : Gst.Bin {
        private dynamic Gst.Element audiosink;
        private dynamic Gst.Element audioqueue;
        private dynamic Gst.Element audiotee;
        private dynamic Gst.Element capsfilter;
        private dynamic Gst.Element equalizer;
        private dynamic Gst.Element audioamplify;
        private dynamic Gst.Element spectrum;
        private const string [] AUDIORENDER = {"autoaudiosink", "alsasink", "pulsesink"};
        private int interval { get; set; default = 50; }
        public int threshold { get; set; default = -80; }
        public float gamma { get; set; default = 3.0f; }
        public uint bands { get; set; default = 10; }
        public float[] m_magnitudes;
        public unowned float[]? get_magnitudes () {
            return m_magnitudes;
        }

        construct {
            m_magnitudes = new float[bands];
            audiotee = Gst.ElementFactory.make("tee", "tee");
            audioqueue = Gst.ElementFactory.make("queue", "queue");
            audioqueue["flush-on-eos"] = true;
            capsfilter = Gst.ElementFactory.make("capsfilter", "capsfilter");
            Gst.Util.set_object_arg ((GLib.Object) capsfilter, "caps", "audio/x-raw, format={ S16LE, F24LE, F32LE, F64LE }");
            equalizer = Gst.ElementFactory.make("equalizer-10bands", "equalizer-10bands");
            double [] freqs = {29, 59, 119, 237, 474, 947, 1889, 3770, 7523, 15011};
            double last_freq = -30;
            uint index = 0;
            foreach (double freq in freqs) {
                GLib.Object? band = ((Gst.ChildProxy) equalizer).get_child_by_index (index);
                band["freq"] = freq;
                double bandwidth = freq - last_freq;
                last_freq = freq;
                band["bandwidth"] = bandwidth;
                index++;
            }
            audioamplify = Gst.ElementFactory.make("audioamplify", "audioamplify");
            audioamplify["amplification"] = 1.15;
            spectrum = Gst.ElementFactory.make("nikispectrum", "nikispectrum");
            spectrum["bands"] = bands;
            spectrum["threshold"] = (float)threshold;
            spectrum["interval"] = (uint64)(interval * 1000 * 1000);
            spectrum["gamma"] = (float)gamma;
            bind_property ("bands", spectrum, "bands");
            bind_property ("threshold", spectrum, "threshold");
            bind_property ("gamma", spectrum, "gamma");
            audiosink = Gst.ElementFactory.make(AUDIORENDER [NikiApp.settings.get_int ("audiorender-options")], AUDIORENDER [NikiApp.settings.get_int ("audiorender-options")]);
            add_many (audioqueue, audiotee, capsfilter, equalizer, spectrum, audioamplify, audiosink);
            add_pad (new Gst.GhostPad ("sink", audiotee.get_static_pad ("sink")));
            audioqueue.link_many(capsfilter, equalizer, spectrum, audioamplify, audiosink);
            Gst.Pad sinkpad = audioqueue.get_static_pad ("sink");
            Gst.Pad pad = audiotee.get_request_pad ("src_%u");
            pad.link(sinkpad);
            audiotee["alloc-pad"] = pad;
        }

        public void setgain (int index, double gain) {
            GLib.Object? band = ((Gst.ChildProxy)equalizer).get_child_by_index (index);
            if (gain < 0) {
                gain *= 0.282f;
            } else {
                gain *= 0.141f;
            }
            band["gain"] = gain;
        }
        public Gee.Collection<EqualizerPreset> get_presets () {
            var equalizer_preset = new Gee.TreeSet<EqualizerPreset>();
            foreach (string preset in NikiApp.settingsEq.get_strv ("custom-presets")) {
                equalizer_preset.add (new EqualizerPreset.from_string (preset));
            }
            return equalizer_preset;
        }

        private static Gee.TreeSet<EqualizerPreset>? default_presets = null;
        public static Gee.Collection<EqualizerPreset> get_default_presets () {
            if (default_presets != null) {
                return default_presets;
            }

            default_presets = new Gee.TreeSet<EqualizerPreset> ();
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Flat, {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Classical, {0, 0, 0, 0, 0, 0, -40, -40, -40, -50}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Club, {0, 0, 20, 30, 30, 30, 20, 0, 0, 0}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Dance, {50, 35, 10, 0, 0, -30, -40, -40, 0, 0}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Full_Bass, {55, 55, 55, 30, 0, -25, -50, -50, -50, -50}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Full_Treble, {-50, -50, -50, -30, -5, 5, 25, 45, 55, 55}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Bass_Treble, {70, 70, 0, -40, -25, 20, 45, 55, 60, 60}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Headphones, {0, 45, -35, -35, -55, -35, -40, -40, 0, 0}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Large_Hall, {50, 50, 30, 30, 0, -25, -25, -25, 0, 0}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Live, {-25, 0, 20, 25, 30, 30, 20, 15, 15, 10}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Party, {35, 35, 0, 0, 0, 0, 0, 0, 35, 35}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Pop, {-10, 25, 35, 40, 25, -5, -15, -15, -10, -10}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Reggae, {0, 0, -5, -30, 0, -35, -35, 0, 0, 0}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Rock, {40, 25, -30, -40, -20, 20, 45, 55, 55, 55}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Soft, {25, 10, -5, -15, -5, 20, 45, 50, 55, 60}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Ska, {-15, -25, -25, -5, 20, 30, 45, 50, 55, 50}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Soft_Rock, {20, 20, 10, -5, -25, -30, -20, -5, 15, 45}));
            default_presets.add (new EqualizerPreset.with_gains (StringPot.Techno, {40, 30, 0, -30, -25, 0, 40, 50, 50, 45}));

            return default_presets;
        }
    }
}
