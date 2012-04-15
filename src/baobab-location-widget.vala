/* -*- indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/* Baobab - disk usage analyzer
 *
 * Copyright (C) 2012  Stefano Facchini <stefano.facchini@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

namespace Baobab {

    public abstract class BaseLocationWidget : Gtk.Grid {

        protected const int ICON_SIZE = 48;

        protected static Gtk.SizeGroup name_size_group = null;
        protected static Gtk.SizeGroup mount_point_size_group = null;
        protected static Gtk.SizeGroup size_size_group = null;
        protected static Gtk.SizeGroup used_size_group = null;
        protected static Gtk.SizeGroup button_size_group = null;

        public delegate void ActionOnClick (Location? location = null);

        protected void ensure_size_groups () {
            if (name_size_group != null)
                return;

            name_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            mount_point_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            size_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            used_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
            button_size_group = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
        }

        public BaseLocationWidget () {
            column_spacing = 10;
            margin = 6;
        }

        protected override void get_preferred_width (out int minimum, out int natural) {
            int min, nat;
            base.get_preferred_width (out min, out nat);

            var state = get_state_flags ();
            var border = get_style_context ().get_padding (state);
            minimum = min + border.left + border.right;
            natural = nat + border.left + border.right;
        }

        protected override void get_preferred_height (out int minimum, out int natural) {
            int min, nat;
            base.get_preferred_height (out min, out nat);

            var state = get_state_flags ();
            var border = get_style_context ().get_padding (state);
            minimum = min + border.top + border.bottom;
            natural = nat + border.top + border.bottom;
        }

        protected override void size_allocate (Gtk.Allocation alloc) {
            var state = get_state_flags ();
            var border = get_style_context ().get_padding (state);

            var adjusted_alloc = Gtk.Allocation ();
            adjusted_alloc.x = alloc.x + border.left;
            adjusted_alloc.y = alloc.y + border.top;
            adjusted_alloc.width = alloc.width - border.left - border.right;
            adjusted_alloc.height = alloc.height - border.top - border.bottom;

            base.size_allocate (adjusted_alloc);

            set_allocation (alloc);
        }

        protected override bool draw (Cairo.Context cr) {
            Gtk.Allocation alloc;
            get_allocation (out alloc);

            get_style_context ().render_background (cr, 0, 0, alloc.width, alloc.height);
            get_style_context ().render_frame (cr, 0, 0, alloc.width, alloc.height);

            base.draw (cr);

            return false;
        }
    }

    public class LocationWidget : BaseLocationWidget {

        public LocationWidget (Location location, BaseLocationWidget.ActionOnClick action) {
            base ();

            ensure_size_groups ();

            var icon_theme = Gtk.IconTheme.get_default ();
            var icon_info = icon_theme.lookup_by_gicon (location.icon, BaseLocationWidget.ICON_SIZE, 0);

            var info_grid = new Gtk.Grid ();

            try {
                var pixbuf = icon_info.load_icon ();
                var image = new Gtk.Image.from_pixbuf (pixbuf);
                info_grid.attach (image, 1, -1, 1, 1);
            } catch (Error e) {
                warning ("Failed to load icon %s: %s", location.icon.to_string(), e.message);
            }

            var label = new Gtk.Label (location.name);
            label.set_markup ("<b>" + location.name + "</b>");
            label.xalign = 0;
            info_grid.attach (label, 2, -1, 1, 1);


            info_grid.column_spacing = 10;
            info_grid.row_spacing = 6;
            info_grid.valign = Gtk.Align.CENTER;

            label = new Gtk.Label (_("Size"));
            label.halign = Gtk.Align.END;
            label.get_style_context ().add_class ("dim-label");
            info_grid.attach (label, 1, 0, 1, 1);

            label = new Gtk.Label (location.size != null ? format_size (location.size) : "");
            label.halign = Gtk.Align.START;
            info_grid.attach (label, 2, 0, 1, 1);


            if (location.used != null) {
                label = new Gtk.Label (_("Usage"));
                label.halign = Gtk.Align.END;
                label.get_style_context ().add_class ("dim-label");
                info_grid.attach (label, 1, 1, 1, 1);

                var progress = new Gtk.ProgressBar ();
                progress.valign = Gtk.Align.CENTER;
                progress.set_fraction ((double) location.used / location.size);
                used_size_group.add_widget (progress);
                info_grid.attach (progress, 2, 1, 1, 1);
            } else {
                label = new Gtk.Label ("");
                info_grid.attach (label, 2, 3, 1, 1);
                used_size_group.add_widget (label);
            }

            label = new Gtk.Label (_("Mounted at"));
            label.halign = Gtk.Align.END;
            label.get_style_context ().add_class ("dim-label");
            info_grid.attach (label, 1, 2, 1, 1);

            label = new Gtk.Label (location.mount_point != null ? location.mount_point : "not mounted");
            //label.hexpand = true;
            label.halign = Gtk.Align.START;
            label.xalign = 0;
            label.max_width_chars = 20;
            label.ellipsize = Pango.EllipsizeMode.END;
            if (location.mount_point != null)
                label.set_tooltip_text (location.mount_point);
            mount_point_size_group.add_widget (label);
            info_grid.attach (label, 2, 2, 1, 1);

            attach (info_grid, 0, 1, 1, 1);

            //size_size_group.add_widget (label);
            //add (label);

            string button_label = location.mount_point != null ? _("Scan") : _("Mount and scan");
            var button = new Gtk.Button.with_label (button_label);
            button.valign = Gtk.Align.CENTER;
            button.halign = Gtk.Align.END;
            button_size_group.add_widget (button);
            attach (button, 0, 2, 1, 1);

            button.clicked.connect(() => { action (location); });

            show_all ();
        }
    }
}
