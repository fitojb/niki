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
    public class PlayerPage : GtkClutter.Embed {
        public PlaybackPlayer? playback;
        public Clutter.Stage stage;
        private ClutterGst.Aspectratio aspect_ratio;
        private Clutter.Actor cover_center;
        private Clutter.Text title_music;
        private Clutter.Text artist_music;
        private Clutter.Text first_lyric;
        private Clutter.Text seconds_lyric;
        private Clutter.Text notify_text;
        public Clutter.Text lyric_sc;
        private Clutter.Image oriimage;
        private Clutter.Image blur_image;
        public RightBar? right_bar;
        private GtkClutter.Actor right_actor;
        public TopBar? top_bar;
        public GtkClutter.Actor top_actor;
        public BottomBar? bottom_bar;
        public NotifyBottomBar? notifybottombar;
        public GtkClutter.Actor bottom_actor;
        private GtkClutter.Actor bottom_actor_notif;
        public Clutter.ScrollActor scroll;
        public Clutter.Actor menu_actor;
        public Clutter.Point point;
        public MPRIS? mpris;
        public int video_height;
        public int video_width;
        private uint mouse_timer = 0;
        private bool _mouse_hovered = false;
        private bool mouse_hovered {
            get {
                return _mouse_hovered;
            }
            set {
                _mouse_hovered = value;
                if (value) {
                    if (mouse_timer != 0) {
                        Source.remove (mouse_timer);
                        mouse_timer = 0;
                    }
                } else {
                    mouse_control ();
                }
            }
        }

        public PlayerPage (Window window) {
            events |= Gdk.EventMask.POINTER_MOTION_MASK;
            playback = new PlaybackPlayer ();
            playback.set_seek_flags (ClutterGst.SeekFlags.ACCURATE);
            stage = get_stage () as Clutter.Stage;
            stage.background_color = Clutter.Color.from_string ("black");
            aspect_ratio = new ClutterGst.Aspectratio ();
            aspect_ratio.player = playback;
            stage.content = aspect_ratio;
            playback.size_change.connect ((width, height) => {
                video_width = width;
                video_height = height;
                if (!NikiApp.settings.get_boolean ("audio-video")) {
                    resize_player_page (width, height);
                    set_size_request (width < 300 && height < 700 || height < 300 && width < 700? width : 100, width < 300 && height < 700 || height < 300 && width < 700? height : 150);
                }
            });
            NikiApp.settings.changed["activate-subtitle"].connect (() => {
                playback.subtitle_track = NikiApp.settings.get_boolean ("activate-subtitle")? playback.get_subtitle_track() : -1;
            });
            mpris = new MPRIS ();
            mpris.bus_acive (playback);

            Clutter.LayoutManager layout_manager = new Clutter.BoxLayout ();
            ((Clutter.BoxLayout) layout_manager).set_orientation (Clutter.Orientation.VERTICAL);
            ((Clutter.BoxLayout) layout_manager).set_spacing (0);
            menu_actor = new Clutter.Actor ();
            menu_actor.set_layout_manager (layout_manager);
            scroll = new Clutter.ScrollActor ();
            scroll.set_scroll_mode (Clutter.ScrollMode.VERTICALLY);
            scroll.add_child (menu_actor);
            stage.add_child (scroll);
            blur_image = new Clutter.Image ();
            oriimage = new Clutter.Image ();
            cover_center = new Clutter.Actor ();
            cover_center.width = 250;
            cover_center.height = 250;
            stage.add_child (cover_center);

            notify_text = new Clutter.Text ();
            notify_text.ellipsize = Pango.EllipsizeMode.END;
            notify_text.color = Clutter.Color.from_string ("white");
            notify_text.background_color = Clutter.Color.from_string ("black") { alpha = 80 };
            notify_text.font_name = "Bitstream Vera Sans Bold 10";
            notify_text.line_alignment = Pango.Alignment.CENTER;
            notify_text.use_markup = true;
            stage.add_child (notify_text);

            first_lyric = new Clutter.Text ();
            first_lyric.ellipsize = Pango.EllipsizeMode.END;
            first_lyric.color = Clutter.Color.from_string ("orange");
            first_lyric.background_color = Clutter.Color.from_string ("black") { alpha = 100 };
            first_lyric.line_alignment = Pango.Alignment.CENTER;
            first_lyric.single_line_mode = true;
            first_lyric.use_markup = true;
            stage.add_child (first_lyric);

            seconds_lyric = new Clutter.Text ();
            seconds_lyric.ellipsize = Pango.EllipsizeMode.END;
            seconds_lyric.color = Clutter.Color.from_string ("white");
            seconds_lyric.background_color = Clutter.Color.from_string ("black") { alpha = 100 };
            seconds_lyric.line_alignment = Pango.Alignment.CENTER;
            seconds_lyric.single_line_mode = true;
            seconds_lyric.use_markup = true;
            stage.add_child (seconds_lyric);

            title_music = new Clutter.Text ();
            title_music.ellipsize = Pango.EllipsizeMode.END;
            title_music.color = Clutter.Color.from_string ("white");
            title_music.background_color = Clutter.Color.from_string ("black") { alpha = 100 };
            title_music.font_name = "Bitstream Vera Sans Bold 16";
            title_music.line_alignment = Pango.Alignment.CENTER;
            title_music.single_line_mode = true;
            title_music.use_markup = true;
            stage.add_child (title_music);

            artist_music = new Clutter.Text ();
            artist_music.ellipsize = Pango.EllipsizeMode.END;
            artist_music.color = Clutter.Color.from_string ("white");
            artist_music.background_color = Clutter.Color.from_string ("black") { alpha = 100 };
            artist_music.font_name = "Lato 17";
            artist_music.line_alignment = Pango.Alignment.CENTER;
            artist_music.single_line_mode = true;
            artist_music.use_markup = true;
            stage.add_child (artist_music);

            right_bar = new RightBar (this);
            right_actor = new GtkClutter.Actor ();
            right_actor.contents = right_bar;
            right_actor.opacity = 255;
            right_actor.add_constraint (new Clutter.AlignConstraint (stage, Clutter.AlignAxis.X_AXIS, 1));
            right_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.HEIGHT, 1));
            stage.add_child (right_actor);

            top_bar = new TopBar (this);
            top_actor = new GtkClutter.Actor ();
            top_actor.contents = top_bar;
            top_actor.opacity = 255;
            top_actor.add_constraint (new Clutter.AlignConstraint (stage, Clutter.AlignAxis.Y_AXIS, 0));
            top_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 0));
            stage.add_child (top_actor);

            notifybottombar = new NotifyBottomBar (this);
            bottom_actor_notif = new GtkClutter.Actor ();
            bottom_actor_notif.contents = notifybottombar;
            bottom_actor_notif.opacity = 255;
            bottom_actor_notif.add_constraint (new Clutter.AlignConstraint (stage, Clutter.AlignAxis.Y_AXIS, 1));
            bottom_actor_notif.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 1));
            stage.add_child (bottom_actor_notif);
            bottom_bar = new BottomBar (this);
            bottom_bar.bind_property ("playing", playback, "playing", BindingFlags.BIDIRECTIONAL);
            bottom_actor = new GtkClutter.Actor ();
            bottom_actor.contents = bottom_bar;
            bottom_actor.opacity = 255;
            bottom_actor.add_constraint (new Clutter.AlignConstraint (stage, Clutter.AlignAxis.Y_AXIS, 1));
            bottom_actor.add_constraint (new Clutter.BindConstraint (stage, Clutter.BindCoordinate.WIDTH, 1));
            stage.add_child (bottom_actor);
            show_all ();

            stage.motion_event.connect ((event) => {
                if (!bottom_bar.child_revealed) {
                    if (event.y > (stage.height - 30)) {
                        bottom_bar.reveal_control ();
                    }
                }
                if (!top_bar.child_revealed) {
                    if (event.y < 20) {
                        top_bar.reveal_control ();
                    }
                }
                return Gdk.EVENT_PROPAGATE;
            });
            motion_notify_event.connect (() => {
                mouse_hovered = window.main_stack.visible_child_name == "welcome"? false : true;
                return false;
            });
            button_press_event.connect ((event) => {
                stage.grab_key_focus ();
                mouse_hovered = false;
                if (event.button == Gdk.BUTTON_PRIMARY && event.type == Gdk.EventType.2BUTTON_PRESS && !right_bar.hovered && !top_bar.hovered && !bottom_bar.hovered) {
                    NikiApp.settings.set_boolean ("fullscreen", !NikiApp.settings.get_boolean ("fullscreen"));
                }

                if (event.button == Gdk.BUTTON_SECONDARY && !right_bar.hovered && !top_bar.hovered && !bottom_bar.hovered) {
                    playback.playing = !playback.playing;
                    string_notify (playback.playing? StringPot.Play : StringPot.Pause);
                }
                return Gdk.EVENT_PROPAGATE;
            });

            button_release_event.connect (() => {
                return mouse_hovered = false;
            });
            playlist_widget ().play.connect ((file, size_path, mediatype, playnow) => {
                play_file (file, size_path, mediatype, playnow);
                playback.notify["idle"].connect (load_current_list);
            });

            bottom_bar.notify["child-revealed"].connect (mouse_blank);
            top_bar.notify["child-revealed"].connect (mouse_blank);
            right_bar.notify["child-revealed"].connect (mouse_blank);
            playlist_widget ().item_added.connect (load_current_list);

            playback.eos.connect (() => {
                playback.progress = 0;
                switch (NikiApp.settings.get_enum ("repeat-mode")) {
                    case RepeatMode.ALL :
                        if (!playlist_widget ().next ()) {
                            playlist_widget ().play_first ();
                        }
                        break;
                    case RepeatMode.ONE :
                        playback.playing = true;
                        break;
                    case RepeatMode.OFF :
                        if (!playlist_widget ().next ()) {
                            playback.playing = false;
                            NikiApp.settings.set_double ("last-stopped", 0);
                            ((Gtk.Image) bottom_bar.play_button.image).icon_name = "com.github.torikulhabib.niki.replay-symbolic";
                            bottom_bar.play_button.tooltip_text = StringPot.Replay;
                            bottom_bar.stop_revealer.set_reveal_child (false);
                            bottom_bar.previous_revealer.set_reveal_child (false);
                            bottom_bar.next_revealer.set_reveal_child (false);
                            Inhibitor.instance.uninhibit ();
                        } else {
                            playback.playing = true;
                        }
                        break;
                }
            });

            playback.notify["progress"].connect (() => {
                if (playback.playing) {
                    if (NikiApp.settings.get_boolean("lyric-available") && NikiApp.settings.get_boolean("audio-video")) {
                        first_lyric.text = bottom_bar.seekbar_widget.get_lyric_now ();
                        seconds_lyric.text = bottom_bar.seekbar_widget.get_lyric_next ();
                        update_position_cover ();
                    }
                }
            });
            playback.notify["buffer-fill"].connect (buffer_fill);
            playback.notify["playing"].connect (signal_playing);
            NikiApp.settings.changed["font-options"].connect (font_option);
            NikiApp.settings.changed["font"].connect (font_option);
            font_option ();
            update_volume ();
            NikiApp.settings.changed["volume-adjust"].connect (update_volume);
            NikiApp.settings.changed["status-muted"].connect (update_volume);

            NikiApp.settings.changed["fullscreen"].connect (() => {
                if (!NikiApp.settings.get_boolean("fullscreen")) {
                    string_notify (StringPot.Press_Esc);
                } else {
                    notify_blank ();
                    if (notify_timer != 0) {
                        Source.remove (notify_timer);
                    }
                    notify_timer = 0;
                }
            });
            NikiApp.settings.changed["blur-mode"].connect (update_bg);
            NikiApp.settings.changed["information-button"].connect (()=> {
                update_position_cover ();
            });

            bottom_bar.notify["child-revealed"].connect (() => {
                notifybottombar.set_reveal_child (false);
            });
            top_bar.button_home.connect (() => {
                playback.playing = false;
                playback.uri = null;
                Inhibitor.instance.uninhibit ();
                resize_player_page (570, 430);
                if (!NikiApp.settings.get_boolean("home-signal")) {
                    NikiApp.settings.set_boolean("home-signal", true);
                    NikiApp.window.main_stack.visible_child_name = "welcome";
                }
                NikiApp.settings.set_string("last-played", " ");
                NikiApp.settings.set_string("uri-video", " ");
                mouse_blank ();
                playlist_widget ().clear_items ();
            });

            playback.ready.connect (signal_window); 
            size_allocate.connect (signal_window);

            NikiApp.settings.changed["home-signal"].connect (() => {
                if (!NikiApp.settings.get_boolean("home-signal")) {
                    if (NikiApp.settings.get_boolean("audio-video")) {
                        resize_player_page (450, 450);
                    }
                }
            });
            NikiApp.settings.changed["audio-video"].connect (() => {
                if (NikiApp.settings.get_boolean("audio-video")) {
                    resize_player_page (450, 450);
                }
                audiovisualisation ();
            });
            NikiApp.settings.changed["visualisation-options"].connect (audiovisualisation);
            if (NikiApp.settings.get_string("subtitle-choose").char_count () > 1) {
                NikiApp.settings.set_string("subtitle-choose", " ");
            }
            audiovisualisation ();
            Idle.add (starting);
            window.welcome_page.getlink.errormsg.connect (string_notify);
        }
        public Playlist? playlist_widget () {
            return right_bar.playlist;
        }
        private void update_bg () {
            if (NikiApp.settings.get_boolean("audio-video")) {
                audio_banner ();
            }
        }
        public void load_current_list () {
            if (NikiApp.window.main_stack.visible_child_name == "player" && !NikiApp.settings.get_boolean("home-signal") && playback.uri != null) {
                playlist_widget ().set_current (playback.uri);
            }
        }
        private void buffer_fill () {
            string_notify (@"$(StringPot.Buffering)$(((int)(playback.get_buffer_fill () * 100)).to_string ())%" );
        }
        public bool starting () {
            if (!playback.playing) {
                if (NikiApp.window.is_privacy_mode_enabled () && !NikiApp.settings.get_boolean("home-signal")) {
                    if (file_exists (NikiApp.settings.get_string("last-played"))) {
                        NikiApp.window.welcome_page.index_but = 3;
                        NikiApp.window.welcome_page.stack.visible_child_name = "circular";
                    } else {
                        gohome ();
                    }
                } else {
                    gohome ();
                }
            } else {
                NikiApp.window.main_stack.visible_child_name = "player";
            }
            return false;
        }
        public Gtk.ListStore restore_file () {
            var liststore = new Gtk.ListStore (1, typeof (string));
            foreach (string restore_last in NikiApp.settings.get_strv ("last-played-videos")) {
                if (!restore_last.has_prefix ("http")) {
                    Gtk.TreeIter iter;
                    liststore.append (out iter);
                    liststore.set (iter, 0, restore_last);
                }
            }
            return liststore;
        }
        public void get_first () {
            if (NikiApp.settings.get_boolean("audio-video")){
                audio_banner ();
                resize_player_page (450, 450);
            }
            if (!NikiApp.settings.get_string("last-played").has_prefix ("http")) {
                playback.uri = NikiApp.settings.get_string("last-played");
                playback.progress = NikiApp.settings.get_double("last-stopped");
                top_bar.label_info.set_label (NikiApp.settings.get_string("title-playing") + get_info_size (playback.uri));
                top_bar.info_label_full.set_label (NikiApp.settings.get_string("title-playing") + get_info_size (playback.uri));
                if (playback.uri.down().contains (NikiApp.settings.get_string("last-played").down())) {
                    NikiApp.settings.set_double("last-stopped", 0);
                }
                NikiApp.settings.set_string ("uri-video", NikiApp.settings.get_string("last-played"));
                sub_lr_check (NikiApp.settings.get_string("last-played"));
                update_position_cover ();
                load_current_list ();
                signal_playing ();
                bottom_bar.stop_revealer.set_reveal_child (false);
            }
        }
        private void gohome () {
            if (!NikiApp.settings.get_boolean("home-signal")) {
                NikiApp.settings.set_boolean("home-signal", true);
            }
            playlist_widget ().clear_items ();
            NikiApp.window.main_stack.visible_child_name = "welcome";
        }
        public void scroll_actor (int index_in) {
            Clutter.Actor menu = scroll.get_first_child ();
            if (index_in > 0) {
                seek_music ();
            }
            Clutter.Actor item = menu.get_child_at_index (index_in);
            item.get_position (out point.x, out point.y);
            point.y = point.y - ((menu_actor.height / 2) - (((Clutter.Text)item).height / 2));
            scroll.save_easing_state ();
            scroll.scroll_to_point (point);
            scroll.restore_easing_state ();
            ((Clutter.Text)item).color = Clutter.Color.from_string ("orange");
            ((GLib.Object)scroll).set_data ("selected-item", index_in.to_pointer ());
        }

        private void font_change () {
            for (int i = 0; i < menu_actor.get_n_children (); i++) {
                Clutter.Actor menu = scroll.get_first_child ();
                Clutter.Actor item = menu.get_child_at_index (i);
                ((Clutter.Text)item).font_name = NikiApp.settings.get_string("font");
            }
        }
        public void seek_music () {
            if (NikiApp.settings.get_boolean("audio-video") && !NikiApp.settings.get_boolean ("information-button") && NikiApp.settings.get_boolean ("lyric-button") && NikiApp.settings.get_boolean("lyric-available")) {
                for (int i = 0; i < menu_actor.get_n_children (); i++) {
                    Clutter.Actor menu = scroll.get_first_child ();
                    Clutter.Actor item = menu.get_child_at_index (i);
                    ((Clutter.Text)item).color = Clutter.Color.from_string ("white");
                }
            }
        }
        public Clutter.Actor text_clutter (string name) {
            lyric_sc = new Clutter.Text ();
            lyric_sc.set_text (name);
            lyric_sc.font_name = NikiApp.settings.get_string("font");
            lyric_sc.color = Clutter.Color.from_string ("white");
            lyric_sc.background_color = Clutter.Color.from_string ("black") { alpha = 100 };
            lyric_sc.set_margin_left (12);
            lyric_sc.set_margin_right (12);
            return lyric_sc;
        }

        public void save_destroy () {
            if (!NikiApp.settings.get_boolean ("home-signal")) {
                if (playback.uri != null) {
                    if (playback.uri.has_prefix ("http")) {
                        NikiApp.settings.set_string("last-played", " ");
                        NikiApp.settings.set_string("uri-video", " ");
                        NikiApp.settings.set_boolean("home-signal", true);
                    } else {
                        NikiApp.settings.set_double ("last-stopped", playback.progress);
                        NikiApp.settings.set_string ("last-played", NikiApp.settings.get_string("uri-video"));
                        playlist_widget ().save_playlist ();
                    }
                }
            }
        }
        public void signal_window () {
            if (NikiApp.settings.get_boolean("audio-video")) {
                int height;
                NikiApp.window.get_size (null, out height);
                menu_actor.height = height - 150;
                update_position_cover ();
            }
            if (notify_timer > 0 ) {
                notify_text.x = (stage.width / 2) - (notify_text.width / 2);
                notify_text.y = ((stage.height / 8) - (notify_text.height / 2));
            }
        }

        private bool audio_banner () {
            Gdk.Pixbuf preview = null;
            Gdk.Pixbuf preview_blur = null;
            switch (NikiApp.settings.get_enum ("player-mode")) {
                case PlayerMode.AUDIO :
                    if (file_exists (NikiApp.settings.get_string("uri-video"))) {
                        Gdk.Pixbuf pixt = pix_from_tag (get_discoverer_info (NikiApp.settings.get_string("uri-video")).get_tags ());
                        preview = align_and_scale_pixbuf (pixt, 764);
                        preview_blur = align_and_scale_pixbuf (pix_mode_blur (pixt), 764);
                    }
                    break;
                case PlayerMode.STREAMAUD :
                    preview = align_and_scale_pixbuf (unknown_cover (), 764);
                    preview_blur = align_and_scale_pixbuf (pix_mode_blur (unknown_cover ()), 764);
                    break;
            }
            if (preview_blur != null && preview != null) {
                try {
                    oriimage.set_data (preview.get_pixels (), Cogl.PixelFormat.RGB_888, preview.width, preview.height, preview.rowstride);
                    cover_center.content = oriimage;
                    blur_image.set_data (preview_blur.get_pixels (), Cogl.PixelFormat.RGBA_8888_PRE, preview_blur.width, preview_blur.height, preview_blur.rowstride);
                    audiovisualisation ();
	            } catch (Error e) {
                    GLib.warning (e.message);
	            }
	        }
	        return Source.REMOVE;
        }
        private void audiovisualisation () {
            if (NikiApp.settings.get_boolean ("audio-video")) {
                set_size_request (450, 450);
            } else {
                set_size_request (100, 150);
            }
            switch (NikiApp.settings.get_int ("visualisation-options")) {
                case 0 :
                    if (!NikiApp.settings.get_boolean("audio-video")) {
                        stage.content = aspect_ratio;
                    } else {
                        stage.content = NikiApp.settings.get_boolean ("blur-mode")? blur_image : oriimage;
                        seek_music ();
                    }
                    break;
                case 1 :
                    stage.content = aspect_ratio;
                    break;
            }
        }

        private bool update_position_cover () {
            scroll.x = NikiApp.settings.get_boolean("audio-video") && !NikiApp.settings.get_boolean ("information-button") && NikiApp.settings.get_boolean ("lyric-button") && NikiApp.settings.get_boolean("lyric-available")? (stage.width / 2) - (scroll.width / 2) : -scroll.width;
            scroll.y = NikiApp.settings.get_boolean("audio-video") && !NikiApp.settings.get_boolean ("information-button") && NikiApp.settings.get_boolean ("lyric-button") && NikiApp.settings.get_boolean("lyric-available")? ((stage.height / 2) - (scroll.height / 2)) : -scroll.height;
            cover_center.x = NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("information-button")? (stage.width / 2) - (cover_center.width / 2) : -cover_center.width;
            cover_center.y = NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("information-button")? ((stage.height / 2) - (cover_center.height / 2) - 50) : -cover_center.height;
            title_music.x = NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("information-button")? ((stage.width / 2) - (title_music.width / 2)) : -title_music.width;
            title_music.y = NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("information-button")? ((stage.height / 2) - (title_music.height / 2) + 90) : -artist_music.height;
            artist_music.x = NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("information-button")? ((stage.width / 2) - (artist_music.width / 2)) : -artist_music.width;
            artist_music.y = NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("information-button")? ((stage.height / 2) - (artist_music.height / 2) + (92 + title_music.height)) : -artist_music.height;
            first_lyric.x = NikiApp.settings.get_boolean ("information-button") && NikiApp.settings.get_boolean("lyric-available") && NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("lyric-button")? ((stage.width / 2) - (first_lyric.width / 2)) : -first_lyric.width;
            first_lyric.y = NikiApp.settings.get_boolean ("information-button") && NikiApp.settings.get_boolean("lyric-available") && NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("lyric-button")? ((stage.height / 2) - (first_lyric.height / 2) + (125 + artist_music.height)) : -first_lyric.height;
            seconds_lyric.x = NikiApp.settings.get_boolean ("information-button") && NikiApp.settings.get_boolean("lyric-available") && NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("lyric-button")? ((stage.width / 2) - (seconds_lyric.width / 2)) : -seconds_lyric.width;
            seconds_lyric.y = NikiApp.settings.get_boolean ("information-button") && NikiApp.settings.get_boolean("lyric-available") && NikiApp.settings.get_boolean("audio-video") && NikiApp.settings.get_boolean ("lyric-button")? ((stage.height / 2) - (seconds_lyric.height / 2) + (155 + first_lyric.height)) : -seconds_lyric.height;
            return Source.REMOVE;
        }

        public void resize_player_page (int width, int height) {
            NikiApp.window.resize (width, height);
        }

        private void font_option () {
            playback.set_subtitle_font_name (NikiApp.settings.get_int("font-options") == 0? "" : NikiApp.settings.get_string("font"));
            first_lyric.font_name = seconds_lyric.font_name = NikiApp.settings.get_string("font");
            font_change ();
        }

        public void mouse_control () {
            cursor_hand_mode (2);
            if (mouse_timer != 0) {
                Source.remove (mouse_timer);
            }
            mouse_timer = GLib.Timeout.add (500, () => {
                if (mouse_hovered || NikiApp.window.main_stack.visible_child_name == "welcome") {
                    mouse_timer = 0;
                    return false;
                }
                mouse_blank ();
                mouse_timer = 0;
                return false;
            });
        }

        public void mouse_blank () {
            if (bottom_bar.child_revealed || right_bar.child_revealed || top_bar.child_revealed) {
                cursor_hand_mode (2);
            } else if (NikiApp.window.main_stack.visible_child_name == "player"){
                cursor_hand_mode (1);
            } else {
                cursor_hand_mode (2);
            }
        }
        private uint notify_timer = 0;
        private void notify_control () {
            notify_text.x = (stage.width / 2) - (notify_text.width / 2);
            notify_text.y = ((stage.height / 8) - (notify_text.height / 2));
            if (notify_timer != 0) {
                Source.remove (notify_timer);
            }
            notify_timer = GLib.Timeout.add (1500, () => {
                notify_blank ();
                notify_timer = 0;
                return Source.REMOVE;
            });
        }

        private void notify_blank () {
            notify_text.x = -notify_text.width;
            notify_text.y = -notify_text.height;
        }

        public void update_volume () {
            playback.audio_volume = NikiApp.settings.get_double ("volume-adjust");
        }

        public void play_file (string uri, string filesize, int mediatype, bool from_beginning = true) {
            NikiApp.settings.set_enum ("player-mode", mediatype);
            top_bar.label_info.set_label (NikiApp.settings.get_string("title-playing") + filesize);
            top_bar.info_label_full.set_label (NikiApp.settings.get_string("title-playing") + filesize);
            if (uri.has_prefix ("http")) {
                NikiApp.settings.set_string("uri-video", uri);
                playback.uri = uri;
                signal_playing ();
                playback.playing = from_beginning;
                check_lr_sub ();
            } else {
                NikiApp.settings.set_string("uri-video", uri);
                if (!uri.down().contains (NikiApp.settings.get_string ("last-played").down())) {
                    playback.uri = uri;
                    playback.progress = 0.0;
                } else {
                    playback.uri = NikiApp.settings.get_string ("last-played");
                    playback.progress = NikiApp.settings.get_double ("last-stopped");
                    NikiApp.settings.set_double ("last-stopped", 0.0);
                }
                sub_lr_check (uri);
                signal_playing ();
                playback.playing = from_beginning;
            }
            if (NikiApp.settings.get_boolean("home-signal")) {
                NikiApp.settings.set_boolean("home-signal", false);
                NikiApp.window.main_stack.visible_child_name = "player";
            }
        }
        private void check_lr_sub () {
            if (NikiApp.settings.get_boolean("subtitle-available")) {
                NikiApp.settings.set_boolean("subtitle-available", false);
                NikiApp.settings.set_string("subtitle-choose", " ");
            }
            if (NikiApp.settings.get_boolean("lyric-available")) {
                NikiApp.settings.set_boolean("lyric-available", false);
            }
            if (menu_actor.get_n_children () > 0) {
                menu_actor.remove_all_children ();
            }
        }
        private void sub_lr_check (string check) {
            check_lr_sub ();
            string? lyric_uri = get_playing_lyric (check);
            if (lyric_uri != null && lyric_uri != check) {
                bottom_bar.seekbar_widget.on_lyric_update (file_lyric (lyric_uri), this);
                NikiApp.settings.set_boolean("lyric-available", true);
            }
            string? sub_uri = get_subtitle_for_uri (check);
            if (sub_uri != null && sub_uri != check) {
                NikiApp.settings.set_string("subtitle-choose", sub_uri);
                NikiApp.settings.set_boolean("subtitle-available", true);
            }
        }

        public void signal_playing () {
            bottom_bar.stop_revealer.set_reveal_child (true);
            if (NikiApp.settings.get_enum ("player-mode") == PlayerMode.VIDEO || NikiApp.settings.get_enum ("player-mode") == PlayerMode.STREAMVID) {
                if (NikiApp.settings.get_boolean("audio-video")) {
                    NikiApp.settings.set_boolean("audio-video", false);
                }
                if (playback.playing) {
                    Inhibitor.instance.inhibit ();
                } else {
                    Inhibitor.instance.uninhibit ();
                }
            } else {
                if (!NikiApp.settings.get_boolean("audio-video")) {
                    NikiApp.settings.set_boolean("audio-video", true);
                }
                if (NikiApp.settings.get_boolean ("lyric-button") && NikiApp.settings.get_boolean ("lyric-available") && playback.playing && !return_hide_mode) {
                    Inhibitor.instance.inhibit ();
                } else {
                    Inhibitor.instance.uninhibit ();
                }
                title_music.text = @" $(NikiApp.settings.get_string ("title-playing")) ";
                artist_music.text = @" $(NikiApp.settings.get_string ("artist-music")) ";
                Idle.add (audio_banner);
            }
            update_position_cover ();
        }

        public void next () {
            if (!playlist_widget ().get_has_next () && NikiApp.settings.get_enum ("repeat-mode") == 1) {
                playlist_widget ().play_first ();
            } else {
                playlist_widget ().next ();
            }
        }

        public void previous () {
            if (!playlist_widget ().get_has_previous () && NikiApp.settings.get_enum ("repeat-mode") == 1) {
                playlist_widget ().play_end ();
            } else {
                playlist_widget ().previous ();
            }
        }

        public void seek_jump_seconds (int seconds) {
            if (NikiApp.settings.get_boolean ("home-signal")) {
                return;
            }
            if (NikiApp.settings.get_int ("speed-playing") != 4) {
                playback.pipeline.set_state (Gst.State.PAUSED);
            }
            var duration = playback.duration;
            var progress = playback.progress;
            var new_progress = ((duration * progress) + (double)seconds)/duration;
            playback.progress = new_progress.clamp (0.0, 1.0);
            if (NikiApp.settings.get_int ("speed-playing") != 4) {
                if (playback.playing) {
                    playback.pipeline.set_state (Gst.State.PLAYING);
                }
            }
            string_notify (bottom_bar.seekbar_widget.duration_n_progress);
            if (!bottom_bar.child_revealed) {
                notifybottombar.reveal_control ();
            }
            seek_music ();
        }

        public void seek_volume (double steps) {
            var new_volume = ((1 * NikiApp.settings.get_double ("volume-adjust")) + (double)steps);
            NikiApp.settings.set_double ("volume-adjust", new_volume.clamp (0.0, 1.0));
            string_notify (double_to_percent (NikiApp.settings.get_double ("volume-adjust")));
        }

        public void string_notify (string notify_string) {
            notify_text.text = @"\n     $(notify_string)     \n";
            notify_control ();
        }
    }
}
