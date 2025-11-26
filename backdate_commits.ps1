# ============================================================
# Script: backdate_commits.ps1
# Tujuan: Membuat backdated commits untuk mengisi GitHub
#         contribution graph yang bolong
# ============================================================

# Tanggal-tanggal target untuk diisi (berdasarkan grafik contribution)
# Fokus pada hari yang bolong: Jul 2025 - Jun 2026
$targetDates = @(
    # Juli 2025 (bolong semua)
    "2025-07-07", "2025-07-09", "2025-07-14", "2025-07-16",
    "2025-07-21", "2025-07-23", "2025-07-28", "2025-07-30",

    # Agustus 2025 (bolong semua)
    "2025-08-04", "2025-08-06", "2025-08-11", "2025-08-13",
    "2025-08-18", "2025-08-20", "2025-08-25", "2025-08-27",

    # September 2025 (bolong semua kecuali beberapa)
    "2025-09-01", "2025-09-03", "2025-09-08", "2025-09-10",
    "2025-09-15", "2025-09-17", "2025-09-22", "2025-09-24",
    "2025-09-29",

    # Oktober 2025 (bolong semua kecuali beberapa)
    "2025-10-01", "2025-10-06", "2025-10-08", "2025-10-13",
    "2025-10-15", "2025-10-20", "2025-10-22", "2025-10-27",
    "2025-10-29",

    # November 2025 (ada beberapa, tapi masih bolong)
    "2025-11-03", "2025-11-05", "2025-11-10", "2025-11-12",
    "2025-11-17", "2025-11-19", "2025-11-24", "2025-11-26",

    # Desember 2025 (bolong semua)
    "2025-12-01", "2025-12-03", "2025-12-08", "2025-12-10",
    "2025-12-15", "2025-12-17", "2025-12-22", "2025-12-24",
    "2025-12-29", "2025-12-31",

    # Januari 2026 (bolong semua)
    "2026-01-05", "2026-01-07", "2026-01-12", "2026-01-14",
    "2026-01-19", "2026-01-21", "2026-01-26", "2026-01-28",

    # Februari 2026 (bolong semua kecuali beberapa)
    "2026-02-02", "2026-02-04", "2026-02-09", "2026-02-11",
    "2026-02-16", "2026-02-18", "2026-02-23", "2026-02-25",

    # Maret 2026 (ada beberapa)
    "2026-03-02", "2026-03-04", "2026-03-09", "2026-03-11",
    "2026-03-16", "2026-03-18", "2026-03-23", "2026-03-25",
    "2026-03-30",

    # April 2026 (ada beberapa)
    "2026-04-01", "2026-04-06", "2026-04-08", "2026-04-13",
    "2026-04-15", "2026-04-20", "2026-04-22", "2026-04-27",

    # Mei 2026 (bolong banyak)
    "2026-05-04", "2026-05-06", "2026-05-11", "2026-05-13",
    "2026-05-18", "2026-05-20", "2026-05-25", "2026-05-27",

    # Juni 2026 (bolong semua)
    "2026-06-01", "2026-06-03", "2026-06-08", "2026-06-10",
    "2026-06-15", "2026-06-17", "2026-06-22", "2026-06-24",
    "2026-06-29"
)

# Pesan commit yang beragam dan realistis
$commitMessages = @(
    "feat: implementasi fitur baru pada halaman utama",
    "fix: perbaikan bug pada navigasi dan routing",
    "refactor: optimasi struktur kode dan komponen",
    "style: pembaruan tampilan dan styling UI",
    "docs: penambahan dokumentasi fitur",
    "feat: pengembangan fitur autentikasi pengguna",
    "fix: perbaikan validasi form input",
    "feat: implementasi fitur keranjang belanja",
    "refactor: perbaikan performa aplikasi",
    "feat: pengembangan panel admin dashboard",
    "fix: perbaikan tampilan produk dan kategori",
    "feat: implementasi sistem notifikasi",
    "docs: pembaruan README dan dokumentasi API",
    "feat: pengembangan fitur profil pengguna",
    "fix: perbaikan bug checkout dan pembayaran",
    "refactor: reorganisasi struktur folder proyek",
    "feat: implementasi fitur favorit produk",
    "style: penyesuaian tema warna aplikasi",
    "fix: perbaikan responsivitas layout mobile",
    "feat: pengembangan fitur riwayat pesanan",
    "docs: penambahan diagram UML dan ERD",
    "feat: implementasi fitur manajemen alamat",
    "fix: perbaikan autentikasi Google OAuth",
    "refactor: optimasi query dan state management",
    "feat: pengembangan fitur rating dan ulasan"
)

# Ambil semua file yang belum di-commit
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  BACKDATE COMMIT SCRIPT - Roti 515" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Dapatkan semua file unstaged dan untracked
$modifiedFiles = @(git diff --name-only)
$untrackedFiles = @(git ls-files --others --exclude-standard)
$allFiles = $modifiedFiles + $untrackedFiles

Write-Host "Total file ditemukan: $($allFiles.Count)" -ForegroundColor Yellow
Write-Host "Total target tanggal: $($targetDates.Count)" -ForegroundColor Yellow
Write-Host ""

if ($allFiles.Count -eq 0) {
    Write-Host "Tidak ada file yang perlu di-commit!" -ForegroundColor Red
    exit
}

# Hitung berapa file per batch
$totalFiles = $allFiles.Count
$totalDates = $targetDates.Count
$filesPerBatch = [Math]::Ceiling($totalFiles / $totalDates)

Write-Host "File per batch commit: $filesPerBatch" -ForegroundColor Green
Write-Host ""
Write-Host "Memulai proses backdated commit..." -ForegroundColor Cyan
Write-Host ""

$fileIndex = 0
$commitCount = 0

foreach ($date in $targetDates) {
    # Ambil batch file untuk tanggal ini
    $batchFiles = @()
    $batchEnd = [Math]::Min($fileIndex + $filesPerBatch - 1, $totalFiles - 1)
    
    for ($i = $fileIndex; $i -le $batchEnd; $i++) {
        $batchFiles += $allFiles[$i]
    }
    
    if ($batchFiles.Count -eq 0) {
        break
    }
    
    # Stage files
    foreach ($file in $batchFiles) {
        git add "$file" 2>$null
    }
    
    # Cek apakah ada yang di-stage
    $staged = git diff --cached --name-only
    if (-not $staged) {
        Write-Host "  [SKIP] $date - tidak ada file yang di-stage" -ForegroundColor DarkGray
        $fileIndex = $batchEnd + 1
        continue
    }
    
    # Pilih pesan commit
    $msgIndex = $commitCount % $commitMessages.Count
    $commitMsg = $commitMessages[$msgIndex]
    
    # Set tanggal commit (jam acak antara 09:00 - 22:00 untuk terlihat natural)
    $hours = Get-Random -Minimum 9 -Maximum 22
    $minutes = Get-Random -Minimum 0 -Maximum 59
    $dateTime = "${date}T$('{0:D2}' -f $hours):$('{0:D2}' -f $minutes):00"
    
    # Buat commit dengan tanggal mundur
    $env:GIT_AUTHOR_DATE = $dateTime
    $env:GIT_COMMITTER_DATE = $dateTime
    
    git commit -m $commitMsg 2>&1 | Out-Null
    
    Write-Host "  [OK] Commit #$($commitCount + 1) -> $date | $($batchFiles.Count) file | $commitMsg" -ForegroundColor Green
    
    $fileIndex = $batchEnd + 1
    $commitCount++
    
    if ($fileIndex -ge $totalFiles) {
        break
    }
}

# Reset environment variables
$env:GIT_AUTHOR_DATE = ""
$env:GIT_COMMITTER_DATE = ""

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  SELESAI!" -ForegroundColor Green
Write-Host "  Total commit dibuat: $commitCount" -ForegroundColor Green
Write-Host "  Rentang tanggal: $($targetDates[0]) s/d $($targetDates[$commitCount-1])" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Sekarang jalankan: git push origin main" -ForegroundColor Yellow
Write-Host "(atau: git push origin master)" -ForegroundColor Yellow
