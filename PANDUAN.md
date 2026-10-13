# Absensi Sekolah — panduan awal

## Status paket
Paket ini berisi aplikasi web responsif yang dapat langsung diuji di komputer/HP melalui browser. Fitur mode demo: login peran admin/guru, dashboard, data siswa dengan foto, kelas, absensi harian, rekap bulanan, ekspor CSV (dapat dibuka di Excel), cetak/simpan PDF melalui dialog print browser, impor CSV siswa, akun demo, dan backup JSON.

**Penting:** mode demo menyimpan data pada `localStorage` browser/perangkat yang sedang dipakai. Ini bukan database online, tidak tersinkron antarperangkat, dan autentikasi demo tidak layak untuk data siswa sungguhan. Jangan gunakan kredensial demo untuk operasional resmi. Integrasi Supabase dan deployment masih perlu dikonfigurasi dengan akun/proyek milik sekolah.

## Login demo
- Admin: `admin` / `admin123`
- Guru: `guru` / `guru123`

## Cara membuka
1. Ekstrak ZIP.
2. Buka `index.html` di browser modern.
3. Untuk cetak laporan, pilih tombol **Cetak / PDF**, lalu pilih **Save as PDF** pada dialog cetak.

## Rekomendasi database online
Supabase Free cocok untuk prototipe: PostgreSQL, autentikasi, dan penyimpanan foto tersedia dengan kuota gratis yang memiliki batas dan dapat berubah. Hosting statis dapat menggunakan GitHub Pages atau layanan hosting statis lain. Periksa syarat penggunaan paket gratis sebelum dipakai sekolah secara resmi.

1. Buat proyek di https://supabase.com dan simpan URL serta anon/publishable key.
2. Di SQL Editor, jalankan SQL skema awal di `supabase-schema.sql`.
3. Aktifkan Email/Password Auth, buat pengguna dari dashboard Supabase, dan buat profil pengguna dengan peran admin/guru.
4. Buat bucket Storage `student-photos` dan atur kebijakan akses privat yang sesuai.
5. Integrasikan SDK Supabase ke aplikasi, ganti penyimpanan localStorage dengan query database, dan terapkan Row Level Security (RLS) sebelum mengunggah data siswa.
6. Deploy file aplikasi melalui GitHub Pages/hosting statis. Uji hak akses admin dan guru menggunakan dua akun terpisah.

SQL pada berkas terpisah adalah fondasi skema, bukan instalasi satu klik. Kebijakan RLS harus ditinjau dan diuji sebelum data nyata dimasukkan.

## Format impor siswa CSV
Header minimal: `NIS,Nama,Kelas`. Nama kelas pada CSV harus sama dengan nama kelas di menu Data Kelas. Kolom opsional: `JK` (nilai `P` untuk perempuan, lainnya dianggap laki-laki). Simpan sebagai CSV UTF-8.

## Sebelum dipakai resmi
- Ganti login demo dengan Supabase Auth dan peran tersimpan di database.
- Terapkan RLS agar guru hanya mengakses kelas yang ditugaskan; admin memiliki akses administrasi.
- Simpan foto di object storage, bukan di localStorage.
- Tentukan kebijakan privasi, retensi, pencadangan, dan akses data anak.
- Uji ekspor, pemulihan backup, dan batas kuota pada perangkat sekolah.
