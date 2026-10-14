import { useEffect, useRef, useState } from 'react';
import { Html5Qrcode } from 'html5-qrcode';
import axios from 'axios';

export default function ScanQr() {
  const scannerRef = useRef(null);
  const isScanningRef = useRef(false);
  const [result, setResult] = useState(null);
  const [scanning, setScanning] = useState(false);

  async function safeStop() {
    if (!scannerRef.current || !isScanningRef.current) return;
    try { await scannerRef.current.stop(); } catch (e) { console.warn('stop() failed:', e); }
    try { scannerRef.current.clear(); } catch (e) { console.warn('clear() failed:', e); }
    isScanningRef.current = false;
  }

  useEffect(() => {
    return () => { safeStop(); };
  }, []);

  async function startScan() {
    setResult(null);
    setScanning(true);
    const scanner = new Html5Qrcode('qr-reader');
    scannerRef.current = scanner;
    try {
      await scanner.start(
        { facingMode: 'environment' },
        { fps: 10, qrbox: 250 },
        async (qr_code) => {
          isScanningRef.current = false;
          await safeStop();
          setScanning(false);
          try {
            const res = await axios.post('http://localhost:3000/api/qr/validate', { qr_code });
            setResult({ ok: true, data: res.data.data.order });
          } catch (e) {
            setResult({ ok: false, msg: e.response?.data?.message || 'Invalid QR' });
          }
        },
        () => {}
      );
      isScanningRef.current = true;
    } catch {
      setScanning(false);
      alert('Camera access failed. Check browser permissions.');
    }
  }

  async function stopScan() {
    await safeStop();
    setScanning(false);
  }

  return (
    <div>
      <h2>Scan QR to Confirm Order</h2>
      <p>Point the camera at the customer's PumpQ Express QR code</p>

      <div className="card" style={{ marginTop: 20, maxWidth: 400 }}>
        <div id="qr-reader" style={{ width: '100%' }} />
        {!scanning && <button onClick={startScan} style={{ marginTop: 14 }}>Start Scanning</button>}
        {scanning && <button onClick={stopScan} style={{ marginTop: 14, background: '#1A1A1A' }}>Stop</button>}
      </div>

      {result && (
        <div className="card" style={{ marginTop: 20, maxWidth: 400 }}>
          {result.ok ? (
            <>
              <h3 style={{ color: '#1A1A1A' }}>Order Confirmed ✓</h3>
              <p>Order #{result.data.order_id} · {result.data.fuel_type} · {result.data.liters}L · ₱{result.data.amount}</p>
            </>
          ) : (
            <p style={{ color: '#B8340A' }}>{result.msg}</p>
          )}
        </div>
      )}
    </div>
  );
}