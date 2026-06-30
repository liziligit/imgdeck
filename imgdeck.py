#!/usr/bin/env python3
"""ImgDeck desktop application for arranging images on an A4 page."""

import os
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

import cv2
import numpy as np
from PIL import Image, ImageTk


A4_RATIO = 210 / 297
LAYOUTS = [
    ("1x1", 1, 1),
    ("2x1", 2, 1),
    ("1x2", 1, 2),
    ("3x1", 3, 1),
    ("1x3", 1, 3),
    ("2x2", 2, 2),
    ("3x2", 3, 2),
    ("3x3", 3, 3),
]
IMAGE_TYPES = [
    ("图片文件", "*.jpg *.jpeg *.png *.webp *.tif *.tiff *.bmp"),
    ("所有文件", "*.*"),
]


class ImageProcessor:
    """Image operations used by the desktop interface."""

    @staticmethod
    def load_images(image_paths):
        images = []
        for path in image_paths:
            if not os.path.exists(path):
                continue
            image = cv2.imread(path)
            if image is not None:
                images.append(image)
        return images

    @staticmethod
    def a4_pixel_size(resolution=72, unit="dpi"):
        if resolution <= 0:
            raise ValueError("Resolution must be positive")
        if unit == "dpi":
            return round(210 / 25.4 * resolution), round(297 / 25.4 * resolution)
        if unit == "dpcm":
            return round(21 * resolution), round(29.7 * resolution)
        raise ValueError("Unit must be 'dpi' or 'dpcm'")

    @staticmethod
    def page_layout(images, rows, cols, width=1240, height=1754):
        if rows < 1 or cols < 1:
            raise ValueError("Rows and columns must be positive")

        page = np.full((height, width, 3), 255, dtype=np.uint8)
        x_edges = np.linspace(0, width, cols + 1, dtype=int)
        y_edges = np.linspace(0, height, rows + 1, dtype=int)

        for index, image in enumerate(images[:rows * cols]):
            row, col = divmod(index, cols)
            x1, x2 = x_edges[col], x_edges[col + 1]
            y1, y2 = y_edges[row], y_edges[row + 1]
            cell_w, cell_h = x2 - x1, y2 - y1
            image_h, image_w = image.shape[:2]

            scale = min(cell_w / image_w, cell_h / image_h)
            new_w = min(cell_w, max(1, int(round(image_w * scale))))
            new_h = min(cell_h, max(1, int(round(image_h * scale))))
            interpolation = cv2.INTER_AREA if scale < 1 else cv2.INTER_LANCZOS4
            resized = cv2.resize(image, (new_w, new_h), interpolation=interpolation)

            image_x = x1 + (cell_w - new_w) // 2
            image_y = y1 + (cell_h - new_h) // 2
            page[image_y:image_y + new_h, image_x:image_x + new_w] = resized

        return page

    @staticmethod
    def save_image(image, output_path, quality=95):
        extension = os.path.splitext(output_path)[1].lower()
        if extension == ".png":
            params = [cv2.IMWRITE_PNG_COMPRESSION, 3]
        elif extension in (".jpg", ".jpeg"):
            params = [cv2.IMWRITE_JPEG_QUALITY, quality]
        else:
            return False
        return cv2.imwrite(output_path, image, params)


class ImgDeckApp:
    """Desktop interface for A4 image layouts."""

    def __init__(self, root: tk.Tk):
        self.root = root
        self.tool = ImageProcessor()
        self.paths = []
        self.result = None
        self.result_size = None
        self.preview_photo = None
        self.layout_key = tk.StringVar(value="1x1")
        self.resolution = tk.StringVar(value="72")
        self.resolution_unit = tk.StringVar(value="每英寸点数")
        self.output_format = tk.StringVar(value="PNG")
        self.resolution_hint = tk.StringVar(value="输出约 595 × 842像素 （40.2 KB）")
        self.selected_image = tk.StringVar(value="所选图片：尚未选择")
        self.status = tk.StringVar(value="请选择图片和选择版式")
        self.layout_cards = {}

        self._build_window()
        self._build_layout()

    def _build_window(self):
        self.root.title("ImgDeck A4 图片拼接")
        self.root.geometry("1120x760")
        self.root.minsize(960, 680)
        self.root.configure(bg="#f3f5f8")

        style = ttk.Style()
        style.configure("Title.TLabel", font=("TkDefaultFont", 20, "bold"))
        style.configure("Hint.TLabel", foreground="#667085")
        style.configure("Action.TButton", padding=(10, 7))

    def _build_layout(self):
        outer = ttk.Frame(self.root, padding=22)
        outer.pack(fill="both", expand=True)

        ttk.Label(outer, text="ImgDeck A4 图片拼接", style="Title.TLabel").pack(anchor="w")
        ttk.Label(
            outer,
            text="选择 1–9 张图片和版式，图片按列表顺序填入，未使用的位置保留白色。",
            style="Hint.TLabel",
        ).pack(anchor="w", pady=(3, 16))

        content = ttk.Frame(outer)
        content.pack(fill="both", expand=True)
        content.columnconfigure(0, minsize=365)
        content.columnconfigure(1, weight=1)
        content.rowconfigure(0, weight=1)

        controls = ttk.LabelFrame(content, text=" 图片与版式 ", padding=14)
        controls.grid(row=0, column=0, sticky="nsew", padx=(0, 16))

        self.listbox = tk.Listbox(
            controls,
            width=38,
            height=7,
            activestyle="none",
            selectbackground="#3b82f6",
            relief="flat",
            borderwidth=1,
        )
        self.listbox.pack(fill="x", pady=(0, 9))
        self.listbox.bind("<<ListboxSelect>>", self._on_list_selection)

        file_buttons = ttk.Frame(controls)
        file_buttons.pack(fill="x")
        ttk.Button(file_buttons, text="添加图片", command=self.add_images, style="Action.TButton").pack(
            side="left", expand=True, fill="x", padx=(0, 4)
        )
        ttk.Button(file_buttons, text="移除", command=self.remove_selected, style="Action.TButton").pack(
            side="left", expand=True, fill="x", padx=(4, 0)
        )

        order_buttons = ttk.Frame(controls)
        order_buttons.pack(fill="x", pady=(7, 13))
        ttk.Button(order_buttons, text="上移", command=lambda: self.move_selected(-1)).pack(
            side="left", expand=True, fill="x", padx=(0, 4)
        )
        ttk.Button(order_buttons, text="下移", command=lambda: self.move_selected(1)).pack(
            side="left", expand=True, fill="x", padx=4
        )
        ttk.Button(order_buttons, text="清空", command=self.clear_images).pack(
            side="left", expand=True, fill="x", padx=(4, 0)
        )

        ttk.Label(controls, text="版式（行 × 列）").pack(anchor="w", pady=(0, 5))
        picker = ttk.Frame(controls)
        picker.pack()
        for index, (key, rows, cols) in enumerate(LAYOUTS):
            self._create_layout_card(picker, key, rows, cols, index)

        resolution_frame = ttk.Frame(controls)
        resolution_frame.pack(fill="x", pady=(10, 0))
        ttk.Label(resolution_frame, text="分辨率：").pack(side="left")
        resolution_input = ttk.Spinbox(
            resolution_frame,
            from_=10,
            to=600,
            increment=1,
            width=6,
            textvariable=self.resolution,
            command=self._resolution_changed,
        )
        resolution_input.pack(side="left", padx=(0, 6))
        resolution_input.bind("<KeyRelease>", self._resolution_changed)
        resolution_input.bind("<FocusOut>", self._resolution_changed)
        unit_input = ttk.Combobox(
            resolution_frame,
            width=11,
            state="readonly",
            textvariable=self.resolution_unit,
            values=("每英寸点数", "每厘米点数"),
        )
        unit_input.pack(side="left")
        unit_input.bind("<<ComboboxSelected>>", self._resolution_changed)
        ttk.Label(controls, textvariable=self.resolution_hint, style="Hint.TLabel").pack(
            anchor="w", pady=(4, 0)
        )

        actions = ttk.Frame(controls)
        actions.pack(pady=(10, 0))
        self.preview_button = tk.Button(
            actions,
            text="预览",
            command=self.combine,
            width=7,
            padx=3,
            pady=5,
            font=("TkDefaultFont", 11, "bold"),
            foreground="#111827",
            background="#dbeafe",
            activeforeground="#111827",
            activebackground="#bfdbfe",
            highlightbackground="#2563eb",
            cursor="hand2",
        )
        self.preview_button.pack(side="left", padx=(0, 8))
        self.save_button = ttk.Button(
            actions, text="保存图片", command=self.save_result, width=10, state="disabled"
        )
        self.save_button.pack(side="left", padx=(0, 6))
        format_input = ttk.Combobox(
            actions,
            width=5,
            state="readonly",
            textvariable=self.output_format,
            values=("PNG", "JPG"),
        )
        format_input.pack(side="left")
        format_input.bind("<<ComboboxSelected>>", self._format_changed)

        status_frame = ttk.Frame(controls, height=38)
        status_frame.pack(fill="x", pady=(8, 0))
        status_frame.pack_propagate(False)
        ttk.Label(
            status_frame,
            textvariable=self.status,
            style="Hint.TLabel",
            wraplength=320,
            justify="left",
        ).pack(anchor="w", fill="x")

        preview_frame = ttk.LabelFrame(content, text=" A4 预览（210 × 297 mm） ", padding=10)
        preview_frame.grid(row=0, column=1, sticky="nsew")
        preview_frame.columnconfigure(0, weight=1)
        preview_frame.rowconfigure(1, weight=1)

        image_info = ttk.Frame(preview_frame, height=42)
        image_info.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        image_info.grid_propagate(False)
        ttk.Label(
            image_info,
            textvariable=self.selected_image,
            wraplength=600,
            justify="left",
        ).grid(row=0, column=0, sticky="nw")

        self.canvas = tk.Canvas(preview_frame, bg="#20242b", highlightthickness=0)
        self.canvas.grid(row=1, column=0, sticky="nsew")
        self.canvas.bind("<Configure>", self._on_canvas_resize)
        self._show_placeholder()

    def _create_layout_card(self, parent, key, rows, cols, index):
        selected = key == self.layout_key.get()
        card = tk.Canvas(
            parent,
            width=68,
            height=82,
            bg="#ffffff",
            highlightthickness=2,
            highlightbackground="#2563eb" if selected else "#d0d5dd",
            cursor="hand2",
        )
        card.grid(row=index // 4, column=index % 4, padx=4, pady=4)

        x1, y1, x2, y2 = 19, 6, 49, 57
        card.create_rectangle(x1, y1, x2, y2, outline="#344054", width=1)
        for col in range(1, cols):
            x = x1 + (x2 - x1) * col / cols
            card.create_line(x, y1, x, y2, fill="#344054")
        for row in range(1, rows):
            y = y1 + (y2 - y1) * row / rows
            card.create_line(x1, y, x2, y, fill="#344054")
        card.create_text(34, 70, text=f"{rows}×{cols}", fill="#101828", font=("TkDefaultFont", 9))
        card.bind("<Button-1>", lambda _event, value=key: self._select_layout(value))
        self.layout_cards[key] = card

    def _select_layout(self, key):
        self.layout_key.set(key)
        for card_key, card in self.layout_cards.items():
            card.configure(highlightbackground="#2563eb" if card_key == key else "#d0d5dd")
        self.invalidate_result()
        self._refresh_status()

    def _layout_shape(self):
        for key, rows, cols in LAYOUTS:
            if key == self.layout_key.get():
                return rows, cols
        return 1, 1

    def _output_size(self):
        try:
            value = float(self.resolution.get())
        except ValueError:
            raise ValueError("请输入有效的分辨率数值。")

        unit = "dpi" if self.resolution_unit.get() == "每英寸点数" else "dpcm"
        maximum = 600 if unit == "dpi" else 240
        if not 1 <= value <= maximum:
            label = "DPI" if unit == "dpi" else "每厘米点数"
            raise ValueError(f"{label} 分辨率应在 1–{maximum} 之间。")
        return self.tool.a4_pixel_size(value, unit)

    def _resolution_changed(self, _event=None):
        try:
            width, height = self._output_size()
            self._update_output_hint(width, height)
            if self.result is not None and self.result_size != (width, height):
                self.status.set("分辨率已调整；当前预览保持不变，点击“预览”后应用新尺寸。")
        except ValueError as exc:
            self.resolution_hint.set(str(exc))

    def _format_changed(self, _event=None):
        try:
            width, height = self._output_size()
            self._update_output_hint(width, height)
        except ValueError as exc:
            self.resolution_hint.set(str(exc))

    def _update_output_hint(self, width, height):
        estimated_bytes = None
        if self.result is not None and self.result_size == (width, height):
            if self.output_format.get() == "PNG":
                extension = ".png"
                params = [cv2.IMWRITE_PNG_COMPRESSION, 3]
            else:
                extension = ".jpg"
                params = [cv2.IMWRITE_JPEG_QUALITY, 95]
            success, encoded = cv2.imencode(extension, self.result, params)
            if success:
                estimated_bytes = encoded.nbytes
        if estimated_bytes is None:
            bytes_per_pixel = 0.0822 if self.output_format.get() == "PNG" else 0.14
            estimated_bytes = width * height * bytes_per_pixel
        self.resolution_hint.set(
            f"输出约 {width} × {height}像素 （{self._format_file_size(estimated_bytes)}）"
        )

    @staticmethod
    def _format_file_size(size_bytes):
        if size_bytes < 1024 * 1024:
            return f"{size_bytes / 1024:.1f} KB"
        return f"{size_bytes / (1024 * 1024):.1f} MB"

    def add_images(self):
        remaining = 9 - len(self.paths)
        if remaining <= 0:
            messagebox.showinfo("数量已满", "最多只能选择 9 张图片。")
            return

        selected = filedialog.askopenfilenames(title="选择要拼接的图片", filetypes=IMAGE_TYPES)
        if not selected:
            return
        if len(selected) > remaining:
            messagebox.showwarning("图片过多", f"最多还能添加 {remaining} 张图片。")
            selected = selected[:remaining]

        first_new_index = len(self.paths)
        self.paths.extend(selected)
        self._refresh_list(first_new_index)
        self.invalidate_result()

    def remove_selected(self):
        selection = self.listbox.curselection()
        if not selection:
            return
        old_index = selection[0]
        del self.paths[old_index]
        next_index = min(old_index, len(self.paths) - 1) if self.paths else None
        self._refresh_list(next_index)
        self.invalidate_result()

    def clear_images(self):
        self.paths.clear()
        self._refresh_list()
        self.invalidate_result()

    def move_selected(self, offset):
        selection = self.listbox.curselection()
        if not selection:
            return
        old_index = selection[0]
        new_index = old_index + offset
        if not 0 <= new_index < len(self.paths):
            return
        self.paths[old_index], self.paths[new_index] = self.paths[new_index], self.paths[old_index]
        self._refresh_list(new_index)
        self.invalidate_result()

    def _refresh_list(self, selected_index=None):
        self.listbox.delete(0, tk.END)
        for index, path in enumerate(self.paths, 1):
            self.listbox.insert(tk.END, f"{index}. {Path(path).name}")
        if self.paths:
            selected_index = 0 if selected_index is None else min(selected_index, len(self.paths) - 1)
            self.listbox.selection_set(selected_index)
            self.listbox.activate(selected_index)
            self.listbox.see(selected_index)
        self._on_list_selection()
        self._refresh_status()

    def _on_list_selection(self, _event=None):
        selection = self.listbox.curselection()
        if not selection:
            self.selected_image.set("所选图片：尚未选择")
            return
        path = os.path.abspath(self.paths[selection[0]])
        self.selected_image.set(f"所选图片：{path}")

    def _refresh_status(self):
        rows, cols = self._layout_shape()
        self.status.set(f"已选择 {len(self.paths)} 张图片；当前 {rows}×{cols} 版式可放 {rows * cols} 张")

    def invalidate_result(self):
        self.result = None
        self.result_size = None
        self.preview_photo = None
        self.save_button.configure(state="disabled")
        self._show_placeholder()

    def combine(self):
        if not self.paths:
            messagebox.showwarning("尚未选择图片", "请至少添加 1 张图片。")
            return

        rows, cols = self._layout_shape()
        capacity = rows * cols

        self.root.configure(cursor="watch")
        self.root.update_idletasks()
        try:
            output_width, output_height = self._output_size()
            images = self.tool.load_images(self.paths)
            if len(images) != len(self.paths):
                raise ValueError("部分图片无法读取，请移除后重新选择。")
            self.result = self.tool.page_layout(images, rows, cols, output_width, output_height)
            self.result_size = (output_width, output_height)
            self._render_preview()
            self._update_output_hint(output_width, output_height)
            shown_count = min(len(images), capacity)
            blank_count = capacity - shown_count
            hidden_count = max(0, len(images) - capacity)
            self.status.set(
                f"A4 预览 {output_width} × {output_height}：显示 {shown_count} 张，"
                f"空白 {blank_count} 个，未显示 {hidden_count} 张"
            )
            self.save_button.configure(state="normal")
        except Exception as exc:
            messagebox.showerror("拼接失败", str(exc))
        finally:
            self.root.configure(cursor="")

    def _page_bounds(self):
        canvas_w = max(self.canvas.winfo_width(), 120)
        canvas_h = max(self.canvas.winfo_height(), 160)
        available_w = max(canvas_w - 36, 80)
        available_h = max(canvas_h - 36, 110)
        ratio = A4_RATIO
        if available_w / available_h > ratio:
            page_h = available_h
            page_w = int(page_h * ratio)
        else:
            page_w = available_w
            page_h = int(page_w / ratio)
        x1 = (canvas_w - page_w) // 2
        y1 = (canvas_h - page_h) // 2
        return x1, y1, x1 + page_w, y1 + page_h

    def _render_preview(self):
        if self.result is None:
            return
        rgb = cv2.cvtColor(self.result, cv2.COLOR_BGR2RGB)
        image = Image.fromarray(rgb)
        x1, y1, x2, y2 = self._page_bounds()
        resampling = getattr(Image, "Resampling", Image).LANCZOS
        image = image.resize((x2 - x1, y2 - y1), resampling)
        self.preview_photo = ImageTk.PhotoImage(image)
        self.canvas.delete("all")
        self.canvas.create_image(x1, y1, image=self.preview_photo, anchor="nw")
        self.canvas.create_rectangle(x1, y1, x2, y2, outline="#98a2b3", width=1)

    def _show_placeholder(self):
        if not hasattr(self, "canvas"):
            return
        self.canvas.delete("all")
        x1, y1, x2, y2 = self._page_bounds()
        self.canvas.create_rectangle(x1, y1, x2, y2, fill="#ffffff", outline="#98a2b3", width=1)

        rows, cols = self._layout_shape()
        for col in range(1, cols):
            x = x1 + (x2 - x1) * col / cols
            self.canvas.create_line(x, y1, x, y2, fill="#d0d5dd")
        for row in range(1, rows):
            y = y1 + (y2 - y1) * row / rows
            self.canvas.create_line(x1, y, x2, y, fill="#d0d5dd")
        for index in range(rows * cols):
            row, col = divmod(index, cols)
            center_x = x1 + (x2 - x1) * (col + 0.5) / cols
            center_y = y1 + (y2 - y1) * (row + 0.5) / rows
            self.canvas.create_text(
                center_x,
                center_y,
                text=str(index + 1),
                fill="#98a2b3",
                font=("TkDefaultFont", 11, "bold"),
            )

    def _on_canvas_resize(self, _event):
        if self.result is not None:
            self._render_preview()
        else:
            self._show_placeholder()

    def save_result(self):
        if self.result is None:
            return
        extension = ".png" if self.output_format.get() == "PNG" else ".jpg"
        file_type = ("PNG 图片", "*.png") if extension == ".png" else ("JPEG 图片", "*.jpg")
        output_path = filedialog.asksaveasfilename(
            title="保存 A4 拼接图片",
            defaultextension=extension,
            initialfile=f"imgdeck_result{extension}",
            filetypes=[file_type],
        )
        if not output_path:
            return
        output_path = f"{os.path.splitext(output_path)[0]}{extension}"
        quality = 60 if extension == ".png" else 95
        if self.tool.save_image(self.result, output_path, quality=quality):
            self.status.set(f"已保存到：{os.path.abspath(output_path)}")
            messagebox.showinfo("保存成功", "A4 拼接图片已保存。")
        else:
            messagebox.showerror("保存失败", "无法保存图片，请检查文件名和保存位置。")


def main():
    root = tk.Tk()
    ImgDeckApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
