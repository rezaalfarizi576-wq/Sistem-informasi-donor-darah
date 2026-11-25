import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> saveFileImpl(Uint8List bytes, String filename) async {
  try {
    final blob = html.Blob([bytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> printHtmlImpl({
  required String reqId,
  required String patientName,
  required String bloodType,
  required String bags,
  required String hospital,
  required String requester,
  required String status,
  required String qrData,
}) async {
  try {
    final qrApiUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${Uri.encodeComponent(qrData)}';
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Bukti Registrasi Permohonan Darah - $reqId</title>
  <style>
    @media print {
      body { margin: 0; padding: 20px; background: white !important; }
      .no-print { display: none !important; }
      .card { box-shadow: none !important; border: 1px solid #cbd5e1 !important; }
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: #f8fafc;
      margin: 0;
      padding: 30px 16px;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    .action-bar {
      margin-bottom: 20px;
      display: flex;
      gap: 12px;
    }
    .btn {
      background: #dc2626;
      color: white;
      border: none;
      padding: 10px 22px;
      border-radius: 8px;
      font-weight: 700;
      font-size: 14px;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      box-shadow: 0 4px 12px rgba(220, 38, 38, 0.25);
    }
    .btn:hover { background: #b91c1c; }
    .card {
      background: white;
      border: 1.5px solid #e2e8f0;
      border-radius: 16px;
      width: 440px;
      max-width: 95vw;
      padding: 28px 24px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.06);
      box-sizing: border-box;
    }
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      border-bottom: 2px solid #f1f5f9;
      padding-bottom: 14px;
      margin-bottom: 18px;
    }
    .logo-box {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .logo-icon {
      width: 32px;
      height: 32px;
      background: #dc2626;
      border-radius: 8px;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-weight: 900;
      font-size: 20px;
    }
    .logo-text h3 { margin: 0; font-size: 12px; color: #dc2626; font-weight: 800; letter-spacing: 0.3px; }
    .logo-text p { margin: 1px 0 0; font-size: 13px; color: #0f172a; font-weight: 900; }
    .badge {
      background: #dcfce7;
      color: #16a34a;
      font-size: 10px;
      font-weight: 800;
      padding: 3px 8px;
      border-radius: 4px;
      border: 1px solid #86efac;
    }
    .qr-section {
      text-align: center;
      margin: 16px 0;
    }
    .qr-section img {
      width: 130px;
      height: 130px;
      border: 1px solid #e2e8f0;
      border-radius: 10px;
      padding: 6px;
    }
    .req-code {
      font-family: monospace;
      font-size: 13px;
      font-weight: 700;
      color: #64748b;
      margin-top: 6px;
    }
    .data-table {
      width: 100%;
      margin-top: 16px;
      border-collapse: collapse;
    }
    .data-table td {
      padding: 7px 2px;
      font-size: 13px;
      vertical-align: top;
    }
    .data-table td.label {
      color: #64748b;
      width: 44%;
      font-weight: 500;
    }
    .data-table td.val {
      color: #0f172a;
      font-weight: 700;
      width: 56%;
    }
    .footer {
      margin-top: 20px;
      text-align: center;
      font-size: 11px;
      color: #94a3b8;
      border-top: 1px dashed #e2e8f0;
      padding-top: 12px;
      line-height: 1.4;
    }
  </style>
</head>
<body>
  <div class="action-bar no-print">
    <button class="btn" onclick="window.print()">🖨️ Cetak / Simpan sebagai PDF</button>
  </div>
  <div class="card">
    <div class="header">
      <div class="logo-box">
        <div class="logo-icon">+</div>
        <div class="logo-text">
          <h3>PALANG MERAH INDONESIA</h3>
          <p>KABUPATEN LAMONGAN</p>
        </div>
      </div>
      <div class="badge">VERIFIED</div>
    </div>
    <div class="qr-section">
      <img src="$qrApiUrl" alt="QR Code">
      <div class="req-code">$reqId</div>
    </div>
    <table class="data-table">
      <tr><td class="label">Nama Pasien</td><td class="val">: $patientName</td></tr>
      <tr><td class="label">Golongan Darah</td><td class="val">: $bloodType</td></tr>
      <tr><td class="label">Jumlah Dibutuhkan</td><td class="val">: $bags</td></tr>
      <tr><td class="label">Faskes Tujuan</td><td class="val">: $hospital</td></tr>
      <tr><td class="label">Pemohon</td><td class="val">: $requester</td></tr>
      <tr><td class="label">Status</td><td class="val">: $status</td></tr>
    </table>
    <div class="footer">
      Dokumen digital resmi Sistem Informasi PMI Kabupaten Lamongan.<br>
      Tunjukkan berkas ini kepada petugas UDD PMI / Bank Darah Rumah Sakit (BDRS).
    </div>
  </div>
  <script>
    window.onload = function() {
      setTimeout(function() { window.print(); }, 500);
    };
  </script>
</body>
</html>
''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
  } catch (_) {}
}
