extends Control
## Panel Kredit - memakai node yang sudah kamu desain di scene:
##   PanelKredit > VBoxContainer > LabelJudul, RichTextLabel, BtnKembaliKredit
## Script ini TIDAK menghapus node milikmu. Ia hanya merapikan layout
## dan mengisi daftar kredit. Node yang hilang akan dibuat otomatis.
## Kredit tersedia dalam dua bahasa, mengikuti pengaturan bahasa.

signal dibuka
signal ditutup

@export_category("Animasi Buka dan Tutup")
@export var durasi_buka: float = 0.45
@export var durasi_tutup: float = 0.25
@export var geser_vertikal: float = 60.0
@export var kedip_layar: int = 4
@export var jeda_antar_elemen: float = 0.07

@export_category("Layout Layar Lebar (PC / HP landscape)")
@export_range(0.0, 0.45) var margin_horizontal: float = 0.20
@export_range(0.0, 0.45) var margin_atas: float = 0.06
@export_range(0.0, 0.45) var margin_bawah: float = 0.22
@export var tombol_kiri_bawah: bool = true
@export_range(0.0, 0.5) var tombol_x: float = 0.09
@export_range(0.5, 1.0) var tombol_y: float = 0.84

@export_category("Layout Layar Sempit (portrait)")
@export_range(0.5, 2.0) var rasio_kompak_di_bawah: float = 1.25
@export_range(0.0, 0.45) var margin_horizontal_kompak: float = 0.06
@export_range(0.0, 0.45) var margin_bawah_kompak: float = 0.05

@export_category("Ukuran Elemen")
@export var jarak_antar_elemen: int = 18
@export var lebar_tombol: float = 260.0
@export var tinggi_tombol: float = 56.0

@export_category("Gaya Teks Kredit (acuan layar 1920x1080)")
@export var ukuran_acuan: Vector2 = Vector2(1920, 1080)
@export var ukuran_bagian: int = 40
@export var ukuran_nama: int = 34
@export var ukuran_keterangan: int = 24
@export var ukuran_penutup: int = 44
@export var warna_aksen: Color = Color8(255, 214, 102)   # judul bagian
@export var warna_nama: Color = Color.WHITE
@export var warna_web: Color = Color8(136, 204, 255)     # tautan
@export var warna_lisensi: Color = Color8(150, 220, 160) # nama lisensi
@export var warna_redup: Color = Color8(190, 190, 200)   # keterangan biasa
@export var outline_teks: int = 6
@export var latar_gelap: bool = true
@export_range(0.0, 1.0) var alpha_latar: float = 0.4

@export_category("Gulir Otomatis")
@export var gulir_otomatis: bool = true
@export var kecepatan_gulir: float = 45.0   # piksel per detik
@export var jeda_awal: float = 1.8
@export var jeda_akhir: float = 3.0
@export var jeda_setelah_sentuh: float = 2.5

@export_category("Isi Kredit - Bahasa Indonesia")
@export var subjudul_id: String = "Terima kasih kepada para kreator aset"
## Format baris:
##   # Judul Bagian                      -> judul bagian (otomatis huruf besar)
##   @ Judul | Pembuat | Lisensi | URL   -> satu aset (Lisensi & URL boleh kosong)
##   Nama | Keterangan                   -> satu orang / teknologi (keterangan boleh URL)
##   ~ catatan kecil                     -> teks kecil redup
##   ---                                 -> garis pemisah
##   * Teks Penutup                      -> teks besar berdenyut
@export_multiline var daftar_kredit_id: String = """
# Dibuat Oleh
VioletteBdg | Kreator Game

# Model 3D
@ PSX Storage Shelves & Cardboard Boxs | Drillimpact | CC BY 4.0 | https://sketchfab.com/3d-models/psx-storage-shelves-cardboard-boxs-07052162b960480898d451e9854b46e8
@ PSXprop - Male Character 02 (Rigged) | Wardster (WardsterOnSketchfab) | Sketchfab Free Standard | https://sketchfab.com/WardsterSAW
@ Character_Male_GreenJacket (Rigged) | Wardster (WardsterOnSketchfab) | CC BY 4.0 | https://sketchfab.com/WardsterSAW
@ FREE PSX PS1 Cardboard Boxes Low Poly - Asset Pack | Stay Retro | CC BY 4.0 | https://stay-retro.itch.io/psx-ps1-cardboard-boxes-low-poly-asset-pack
@ FREE PSX Horror Enemies Lite - Lurcher | Tri Hard Studio | Lisensi Tri Hard Studio | https://tri-hard-studio.itch.io/

# Tekstur
@ RetroUrban Free - 40 Stylized Urban Materials | Binbun3D | CC BY 4.0 | https://binbun3d.itch.io/retrourban-free

# Musik & Efek Suara
@ TUBULAR BELL STRIKE 010 | sandyrb | CC BY 4.0 | https://freesound.org/s/85804/
@ Horror UI Select Stinger 01 | TommasoMotteran | CC BY 4.0 | https://freesound.org/s/858948/

# Teknologi
Godot Engine 4 | godotengine.org
~ Godot Engine © Juan Linietsky, Ariel Manzur & kontributor Godot (Lisensi MIT)

# Lisensi
CC BY 4.0 | creativecommons.org/licenses/by/4.0
~ Creative Commons Attribution 4.0 International
~ Aset dipakai sesuai ketentuan masing-masing pembuat
~ Dilarang menjual ulang game ini

# Terima Kasih Khusus
Para Penguji Game | Atas masukan dan kesabarannya
Komunitas Godot | Atas ilmu yang dibagikan
---
* Terima Kasih Telah Bermain
~ © 2026 VioletteBdg
"""

@export_category("Isi Kredit - English")
@export var subjudul_en: String = "Thanks to the asset creators"
@export_multiline var daftar_kredit_en: String = """
# Created By
VioletteBdg | Game Creator

# 3D Models
@ PSX Storage Shelves & Cardboard Boxs | Drillimpact | CC BY 4.0 | https://sketchfab.com/3d-models/psx-storage-shelves-cardboard-boxs-07052162b960480898d451e9854b46e8
@ PSXprop - Male Character 02 (Rigged) | Wardster (WardsterOnSketchfab) | Sketchfab Free Standard | https://sketchfab.com/WardsterSAW
@ Character_Male_GreenJacket (Rigged) | Wardster (WardsterOnSketchfab) | CC BY 4.0 | https://sketchfab.com/WardsterSAW
@ FREE PSX PS1 Cardboard Boxes Low Poly - Asset Pack | Stay Retro | CC BY 4.0 | https://stay-retro.itch.io/psx-ps1-cardboard-boxes-low-poly-asset-pack
@ FREE PSX Horror Enemies Lite - Lurcher | Tri Hard Studio | Tri Hard Studio License | https://tri-hard-studio.itch.io/

# Textures
@ RetroUrban Free - 40 Stylized Urban Materials | Binbun3D | CC BY 4.0 | https://binbun3d.itch.io/retrourban-free

# Music & Sound Effects
@ TUBULAR BELL STRIKE 010 | sandyrb | CC BY 4.0 | https://freesound.org/s/85804/
@ Horror UI Select Stinger 01 | TommasoMotteran | CC BY 4.0 | https://freesound.org/s/858948/

# Technology
Godot Engine 4 | godotengine.org
~ Godot Engine © Juan Linietsky, Ariel Manzur & Godot contributors (MIT License)

# License
CC BY 4.0 | creativecommons.org/licenses/by/4.0
~ Creative Commons Attribution 4.0 International
~ Assets are used under the terms of each creator
~ Do not resell this game

# Special Thanks
Playtesters | For their feedback and patience
Godot Community | For the knowledge shared
---
* Thank You for Playing
~ © 2026 VioletteBdg
"""

var panel_tengah: VBoxContainer
var lbl_judul: Label
var rich_kredit: RichTextLabel
var btn_kembali: Button
var _tween: Tween
var _posisi_awal: Vector2
var _terbuka: bool = false

# status gulir otomatis
var _acc: float = 0.0
var _jeda: float = 0.0
var _ulang: bool = false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(false)

	_ambil_atau_buat_node()
	Pengaturan.daftarkan_teks(lbl_judul, "MENU_KREDIT")
	Pengaturan.daftarkan_teks(btn_kembali, "UI_KEMBALI")
	_rapikan_layout()
	_isi_kredit()

	if not btn_kembali.pressed.is_connected(tutup):
		btn_kembali.pressed.connect(tutup)
	if not btn_kembali.mouse_entered.is_connected(_hover):
		btn_kembali.mouse_entered.connect(_hover.bind(btn_kembali, 1.06))
		btn_kembali.mouse_exited.connect(_hover.bind(btn_kembali, 1.0))
	rich_kredit.gui_input.connect(_saat_input_kredit)
	rich_kredit.meta_clicked.connect(_saat_tautan)

	# Susun ulang kalau ukuran layar / orientasi berubah
	get_viewport().size_changed.connect(_saat_layar_berubah)
	# Ganti isi kredit kalau bahasa diubah
	Pengaturan.berubah.connect(_saat_pengaturan_berubah)


func _saat_layar_berubah() -> void:
	_rapikan_layout()
	_isi_kredit()


func _saat_pengaturan_berubah(kunci: String) -> void:
	if kunci == "bahasa" or kunci == "semua":
		_isi_kredit()


# ---------------------------------------------------------------
# 1. Pakai node desainmu; buat hanya kalau belum ada
# ---------------------------------------------------------------
func _ambil_atau_buat_node() -> void:
	panel_tengah = find_child("VBoxContainer", true, false) as VBoxContainer
	if panel_tengah == null:
		panel_tengah = VBoxContainer.new()
		panel_tengah.name = "VBoxContainer"
		add_child(panel_tengah)

	lbl_judul = find_child("LabelJudul", true, false) as Label
	if lbl_judul == null:
		lbl_judul = Label.new()
		lbl_judul.name = "LabelJudul"
		lbl_judul.text = "KREDIT"
		panel_tengah.add_child(lbl_judul)
		panel_tengah.move_child(lbl_judul, 0)

	rich_kredit = find_child("RichTextLabel", true, false) as RichTextLabel
	if rich_kredit == null:
		rich_kredit = RichTextLabel.new()
		rich_kredit.name = "RichTextLabel"
		panel_tengah.add_child(rich_kredit)

	btn_kembali = find_child("BtnKembaliKredit", true, false) as Button
	if btn_kembali == null:
		btn_kembali = Button.new()
		btn_kembali.name = "BtnKembaliKredit"
		btn_kembali.text = "KEMBALI"
		panel_tengah.add_child(btn_kembali)


# ---------------------------------------------------------------
# 2. Layout fleksibel (PC / HP landscape / portrait)
# ---------------------------------------------------------------
func _ukuran_layar() -> Vector2:
	var v: Vector2 = get_viewport_rect().size
	return Vector2(maxf(v.x, 1.0), maxf(v.y, 1.0))


func _skala() -> float:
	var v: Vector2 = _ukuran_layar()
	var s: float = minf(v.x / ukuran_acuan.x, v.y / ukuran_acuan.y)
	return clampf(s, 0.5, 2.0)


func _kompak() -> bool:
	var v: Vector2 = _ukuran_layar()
	return (v.x / v.y) < rasio_kompak_di_bawah


func _mh() -> float:
	return margin_horizontal_kompak if _kompak() else margin_horizontal


func _mb() -> float:
	if _kompak() or not tombol_kiri_bawah:
		return margin_bawah_kompak
	return margin_bawah


func _rapikan_layout() -> void:
	var s: float = _skala()
	var kompak: bool = _kompak()

	panel_tengah.set_anchor(SIDE_LEFT, _mh())
	panel_tengah.set_anchor(SIDE_RIGHT, 1.0 - _mh())
	panel_tengah.set_anchor(SIDE_TOP, margin_atas)
	panel_tengah.set_anchor(SIDE_BOTTOM, 1.0 - _mb())
	panel_tengah.offset_left = 0
	panel_tengah.offset_right = 0
	panel_tengah.offset_top = 0
	panel_tengah.offset_bottom = 0
	panel_tengah.alignment = BoxContainer.ALIGNMENT_BEGIN
	panel_tengah.add_theme_constant_override("separation", roundi(jarak_antar_elemen * s))

	lbl_judul.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_judul.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	# Daftar kredit
	rich_kredit.bbcode_enabled = true
	rich_kredit.fit_content = false
	rich_kredit.scroll_active = true
	rich_kredit.selection_enabled = false
	rich_kredit.context_menu_enabled = false
	rich_kredit.focus_mode = Control.FOCUS_NONE
	rich_kredit.mouse_filter = Control.MOUSE_FILTER_STOP
	rich_kredit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rich_kredit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rich_kredit.custom_minimum_size = Vector2(0, 120)
	rich_kredit.get_v_scroll_bar().modulate.a = 0.3

	# Outline hitam supaya teks pixel mudah dibaca di atas background ramai
	rich_kredit.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	rich_kredit.add_theme_constant_override("outline_size", roundi(outline_teks * s))

	# Latar gelap transparan di belakang daftar kredit
	if latar_gelap:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, alpha_latar)
		var m: float = 24.0 * s
		sb.content_margin_left = m
		sb.content_margin_right = m
		sb.content_margin_top = m * 0.6
		sb.content_margin_bottom = m * 0.6
		rich_kredit.add_theme_stylebox_override("normal", sb)

	# Tombol Kembali
	btn_kembali.custom_minimum_size = Vector2(lebar_tombol * s, tinggi_tombol * s)
	btn_kembali.focus_mode = Control.FOCUS_ALL

	if tombol_kiri_bawah and not kompak:
		# Kiri bawah, seperti panel Pengaturan
		if btn_kembali.get_parent() != self:
			btn_kembali.reparent(self, false)
		var w: float = lebar_tombol * s
		var h: float = tinggi_tombol * s
		btn_kembali.set_anchor(SIDE_LEFT, tombol_x)
		btn_kembali.set_anchor(SIDE_RIGHT, tombol_x)
		btn_kembali.set_anchor(SIDE_TOP, tombol_y)
		btn_kembali.set_anchor(SIDE_BOTTOM, tombol_y)
		btn_kembali.offset_left = 0
		btn_kembali.offset_right = w
		btn_kembali.offset_top = -h
		btn_kembali.offset_bottom = 0
		btn_kembali.grow_horizontal = Control.GROW_DIRECTION_END
		btn_kembali.grow_vertical = Control.GROW_DIRECTION_BEGIN
	else:
		# Tengah bawah, di dalam VBoxContainer
		if btn_kembali.get_parent() != panel_tengah:
			btn_kembali.reparent(panel_tengah, false)
		panel_tengah.move_child(btn_kembali, panel_tengah.get_child_count() - 1)
		btn_kembali.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_kembali.size_flags_vertical = Control.SIZE_SHRINK_END


# ---------------------------------------------------------------
# 3. Susun teks kredit (font bawaan desainmu tetap dipakai)
# ---------------------------------------------------------------
## true kalau bahasa aktif English (index 1 di Pengaturan)
func _pakai_inggris() -> bool:
	return int(Pengaturan.get_nilai("bahasa")) == 1


func _tautan(url_mentah: String, hex: String, ukuran: int) -> String:
	var url: String = url_mentah.strip_edges()
	if not (url.begins_with("http://") or url.begins_with("https://")):
		url = "https://" + url
	var tampil: String = url.replace("https://", "").replace("http://", "").replace("www.", "")
	if tampil.length() > 38:
		tampil = tampil.split("/")[0] + "/…"
	return "[font_size=%d][url=%s][color=#%s]%s[/color][/url][/font_size]\n" % [ukuran, url, hex, tampil]


func _isi_kredit() -> void:
	var s: float = _skala()
	var u_bagian: int = roundi(ukuran_bagian * s)
	var u_nama: int = roundi(ukuran_nama * s)
	var u_ket: int = roundi(ukuran_keterangan * s)
	var u_penutup: int = roundi(ukuran_penutup * s)

	var en: bool = _pakai_inggris()
	var isi: String = daftar_kredit_en if en else daftar_kredit_id
	var sub: String = subjudul_en if en else subjudul_id
	var kata_oleh: String = "by" if en else "oleh"

	var hex_aksen: String = warna_aksen.to_html(false)
	var hex_nama: String = warna_nama.to_html(false)
	var hex_web: String = warna_web.to_html(false)
	var hex_lisensi: String = warna_lisensi.to_html(false)
	var hex_redup: String = warna_redup.to_html(false)
	var pemisah: String = "[font_size=%d][color=#%s]- - - - -[/color][/font_size]" % [u_ket, hex_redup]

	var t: String = "[center]"
	if sub != "":
		t += "[font_size=%d][color=#%s]%s[/color][/font_size]\n\n%s\n\n\n" \
			% [u_ket, hex_redup, sub.replace("[", "[lb]"), pemisah]

	var bagian_pertama: bool = true
	for baris_mentah in isi.strip_edges().split("\n"):
		var baris: String = baris_mentah.strip_edges()
		if baris == "":
			continue
		baris = baris.replace("[", "[lb]")  # cegah BBCode tak sengaja

		if baris.begins_with("# "):
			# Judul bagian kuning, tanpa garis pemisah di bawahnya
			if not bagian_pertama:
				t += "\n\n"
			bagian_pertama = false
			t += "[font_size=%d][color=#%s]%s[/color][/font_size]\n\n" \
				% [u_bagian, hex_aksen, baris.substr(2).strip_edges().to_upper()]

		elif baris == "---":
			t += "\n%s\n\n" % pemisah

		elif baris.begins_with("~ "):
			t += "[font_size=%d][color=#%s]%s[/color][/font_size]\n" \
				% [u_ket, hex_redup, baris.substr(2).strip_edges()]

		elif baris.begins_with("* "):
			t += "\n[font_size=%d][pulse freq=1.2 color=#ffffff60 ease=-2.0][color=#%s]%s[/color][/pulse][/font_size]\n\n" \
				% [u_penutup, hex_nama, baris.substr(2).strip_edges().to_upper()]

		elif baris.begins_with("@ "):
			# @ Judul | Pembuat | Lisensi | URL
			var f: PackedStringArray = baris.substr(2).split("|")
			var judul: String = f[0].strip_edges() if f.size() > 0 else ""
			var pembuat: String = f[1].strip_edges() if f.size() > 1 else ""
			var lisensi: String = f[2].strip_edges() if f.size() > 2 else ""
			var url: String = f[3].strip_edges() if f.size() > 3 else ""

			t += "[font_size=%d][color=#%s]%s[/color][/font_size]\n" % [u_nama, hex_nama, judul]
			if pembuat != "":
				t += "[font_size=%d][color=#%s]%s %s[/color][/font_size]\n" % [u_ket, hex_redup, kata_oleh, pembuat]
			if lisensi != "":
				t += "[font_size=%d][color=#%s]%s[/color][/font_size]\n" % [u_ket, hex_lisensi, lisensi]
			if url != "":
				t += _tautan(url, hex_web, u_ket)
			t += "\n"

		else:
			var kolom: PackedStringArray = baris.split("|")
			var nama: String = kolom[0].strip_edges() if kolom.size() > 0 else ""
			var ket: String = kolom[1].strip_edges() if kolom.size() > 1 else ""
			t += "[font_size=%d][color=#%s]%s[/color][/font_size]\n" % [u_nama, hex_nama, nama]
			if ket != "":
				var adalah_web: bool = ket.contains(".") and not ket.contains(" ")
				if adalah_web:
					t += _tautan(ket, hex_web, u_ket)
				else:
					t += "[font_size=%d][color=#%s]%s[/color][/font_size]\n" % [u_ket, hex_redup, ket]
			t += "\n"

	t += "\n[/center]"
	rich_kredit.text = t


# ---------------------------------------------------------------
# Input: tautan, geser jari/mouse, jeda gulir otomatis
# ---------------------------------------------------------------
func _saat_tautan(meta: Variant) -> void:
	var url: String = str(meta)
	if url.begins_with("http://") or url.begins_with("https://"):
		OS.shell_open(url)


func _saat_input_kredit(event: InputEvent) -> void:
	var disentuh: bool = false
	var sb: VScrollBar = rich_kredit.get_v_scroll_bar()

	if event is InputEventMouseButton:
		disentuh = true
	elif event is InputEventMouseMotion:
		var gerak := event as InputEventMouseMotion
		if (gerak.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			disentuh = true
			sb.value -= gerak.relative.y   # geser dengan jari / drag mouse
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		disentuh = true
		if not Input.is_emulating_mouse_from_touch():
			sb.value -= drag.relative.y

	if disentuh:
		_jeda = jeda_setelah_sentuh
		_ulang = false
		_acc = sb.value


func _process(delta: float) -> void:
	if not _terbuka or not gulir_otomatis:
		return

	var sb: VScrollBar = rich_kredit.get_v_scroll_bar()
	var maks: float = sb.max_value - sb.page
	if maks <= 0.0:
		return

	if _jeda > 0.0:
		_jeda -= delta
		_acc = sb.value
		if _jeda <= 0.0 and _ulang:
			_ulang = false
			sb.value = 0.0
			_acc = 0.0
			_jeda = jeda_awal
		return

	if absf(sb.value - _acc) > 2.0:  # pemain menggulir manual
		_acc = sb.value

	if _acc >= maks - 0.5:
		_ulang = true
		_jeda = jeda_akhir
		return

	_acc += kecepatan_gulir * _skala() * delta
	sb.value = _acc


# ---------------------------------------------------------------
# Buka / Tutup
# ---------------------------------------------------------------
func buka() -> void:
	if _terbuka:
		return
	_terbuka = true
	dibuka.emit()
	visible = true
	modulate.a = 1.0

	if _tween and _tween.is_valid():
		_tween.kill()

	# Tunggu 1 frame supaya ukuran layar/container sudah final
	await get_tree().process_frame
	if not _terbuka:
		return # ditutup lagi saat menunggu frame
	_hitung_posisi_awal()

	# Mulai kredit dari atas
	rich_kredit.get_v_scroll_bar().value = 0.0
	_acc = 0.0
	_ulang = false
	_jeda = jeda_awal
	set_process(true)

	panel_tengah.modulate.a = 0.0
	panel_tengah.position = _posisi_awal + Vector2(0.0, geser_vertikal)

	_tween = create_tween()

	for i in kedip_layar:
		_tween.tween_property(self, "modulate:a", randf_range(0.25, 0.85), 0.035)
	_tween.tween_property(self, "modulate:a", 1.0, 0.035)

	_tween.tween_property(panel_tengah, "modulate:a", 1.0, durasi_buka * 0.5)
	_tween.parallel().tween_property(panel_tengah, "position", _posisi_awal, durasi_buka) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var urutan: int = 0
	for c in panel_tengah.get_children():
		if c is Control:
			_munculkan(c, urutan * jeda_antar_elemen)
			urutan += 1
	if btn_kembali.get_parent() == self:
		_munculkan(btn_kembali, urutan * jeda_antar_elemen)

	btn_kembali.grab_focus()


## Posisi tujuan dihitung dari anchor + ukuran layar (bukan dibaca dari posisi
## saat ini), jadi tidak akan bergeser walau dibuka/ditutup berkali-kali.
func _hitung_posisi_awal() -> void:
	_posisi_awal = Vector2(size.x * _mh(), size.y * margin_atas)


func _munculkan(c: Control, tunda: float) -> void:
	c.pivot_offset = c.size * 0.5
	c.modulate.a = 0.0
	c.scale = Vector2(0.9, 0.9)
	var t := create_tween()
	t.tween_interval(tunda)
	t.set_parallel(true)
	t.tween_property(c, "modulate:a", 1.0, 0.25)
	t.tween_property(c, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func tutup() -> void:
	if not _terbuka:
		return
	_terbuka = false
	ditutup.emit()
	if _tween and _tween.is_valid():
		_tween.kill()
	_hitung_posisi_awal()

	var t := create_tween()
	t.tween_property(panel_tengah, "modulate:a", 0.0, durasi_tutup)
	t.parallel().tween_property(panel_tengah, "position", _posisi_awal + Vector2(0.0, geser_vertikal), durasi_tutup) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(self, "modulate:a", 0.0, durasi_tutup)
	t.tween_callback(func():
		visible = false
		set_process(false)
		_hitung_posisi_awal()
		panel_tengah.position = _posisi_awal
		panel_tengah.modulate.a = 1.0
	)
	_tween = t


func _hover(c: Control, skala: float = 1.06) -> void:
	c.pivot_offset = c.size * 0.5
	var t := create_tween()
	t.tween_property(c, "scale", Vector2(skala, skala), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
