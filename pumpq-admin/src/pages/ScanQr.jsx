import { useEffect, useRef, useState } from 'react';
import { Html5Qrcode } from 'html5-qrcode';
import axios from 'axios';

const ORANGE = '#E8450A';

const S = {
  card: { background: '#fff', borderRadius: 16, boxShadow: '0 2px 10px rgba(0,0,0,0.04)', border: '1px solid #F0F0F0', padding: 20 },
  label: { fontSize: 11, textTransform: 'uppercase', color: '#999', letterSpacing: 0.4 },
  ghost: {
    background: '#fff', color: '#444', border: '1px solid #E5E5E5', borderRadius: 10,
    padding: '9px 16px', fontSize: 13, fontWeight: 600, cursor: 'pointer', boxShadow: 'none', width: 'auto',
  },
};

export default function ScanQr() {
  const scannerRef = useRef(null);
  const isScanningRef = useRef(false);
  const [result, setResult] = useState(null);
  const [scanning, setScanning] = useState(false);
  const [manualCode, setManualCode] = useState('');
  const [stats, setStats] = useState({ confirmed: 0, failed: 0 });

  async function safeStop() {
    if (!scannerRef.current || !isScanningRef.current) return;
    try { await scannerRef.current.stop(); } catch {}
    try { scannerRef.current.clear(); } catch {}
    isScanningRef.current = false;
  }

  useEffect(() => {
    startScan();
    return () => { safeStop(); };
  }, []);

  async function confirmOrder(qr_code) {
    try {
      const res = await axios.post('http://localhost:3000/api/qr/validate', { qr_code });
      setResult({ ok: true, data: res.data.data.order });
      setStats((s) => ({ ...s, confirmed: s.confirmed + 1 }));
    } catch (e) {
      setResult({ ok: false, msg: e.response?.data?.message || 'Invalid QR' });
      setStats((s) => ({ ...s, failed: s.failed + 1 }));
    }
  }

  async function startScan() {
    if (isScanningRef.current) return;
    setResult(null);
    setScanning(true);
    const scanner = new Html5Qrcode('qr-reader');
    scannerRef.current = scanner;
    try {
      await scanner.start(
        { facingMode: 'environment' },
        { fps: 10, qrbox: 230, aspectRatio: 16 / 9 },
        async (qr_code) => {
          await safeStop();
          setScanning(false);
          confirmOrder(qr_code);
        },
        () => {}
      );
      isScanningRef.current = true;
    } catch {
      setScanning(false);
      alert('Camera access failed. Check browser permissions.');
    }
  }

  async function stopCamera() {
    await safeStop();
    setScanning(false);
  }

  async function handleManualSubmit(e) {
    e.preventDefault();
    if (!manualCode.trim()) return;
    await safeStop();
    setScanning(false);
    confirmOrder(manualCode.trim());
    setManualCode('');
  }

  function scanAgain() {
    setResult(null);
    startScan();
  }

  return (
    <div>
      <style>{`
        #qr-reader { border: none !important; }
        #qr-reader video { width: 100% !important; height: 100% !important; object-fit: cover; }
      `}</style>

      <h2>Scan QR to Confirm Order</h2>
      <p>Point the camera at the customer's PumpQ Express QR code</p>

      <div style={{ display: 'flex', gap: 20, marginTop: 20, alignItems: 'flex-start' }}>
        {/* Camera */}
        <div style={{ ...S.card, flex: 1.6, minWidth: 0 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <h3 style={{ margin: 0 }}>Camera</h3>
              <span style={{
                display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 11, fontWeight: 600,
                padding: '3px 10px', borderRadius: 999,
                background: scanning ? '#E6F6EC' : '#F0F0F0', color: scanning ? '#1E8E4E' : '#888',
              }}>
                <span style={{ width: 6, height: 6, borderRadius: '50%', background: scanning ? '#1E8E4E' : '#AAA' }} />
                {scanning ? 'On' : 'Off'}
              </span>
            </div>
            {scanning ? (
              <button onClick={stopCamera} style={S.ghost}>Close Camera</button>
            ) : (
              <button onClick={startScan} style={{ padding: '9px 16px', width: 'auto' }}>Open Camera</button>
            )}
          </div>

          <div style={{ position: 'relative', aspectRatio: '16 / 9', borderRadius: 14, overflow: 'hidden', background: '#111' }}>
            <div id="qr-reader" style={{ width: '100%', height: '100%' }} />
            {!scanning && (
              <div style={{
                position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'center', gap: 8, background: '#111', color: '#888', fontSize: 13,
              }}>
                <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M23 7l-7 5 7 5V7z" /><rect x="1" y="5" width="15" height="14" rx="2" />
                  <line x1="2" y1="2" x2="22" y2="22" />
                </svg>
                Camera is off
              </div>
            )}
          </div>
        </div>

        {/* Side column */}
        <div style={{ width: 320, display: 'flex', flexDirection: 'column', gap: 16, flexShrink: 0 }}>
          <div style={{ display: 'flex', gap: 16 }}>
            <div style={{ ...S.card, flex: 1, padding: 16 }}>
              <div style={S.label}>Confirmed</div>
              <div style={{ fontSize: 28, fontWeight: 700, color: '#1A1A1A', marginTop: 6 }}>{stats.confirmed}</div>
            </div>
            <div style={{ ...S.card, flex: 1, padding: 16 }}>
              <div style={S.label}>Failed</div>
              <div style={{ fontSize: 28, fontWeight: 700, color: '#B8340A', marginTop: 6 }}>{stats.failed}</div>
            </div>
          </div>

          <div style={S.card}>
            <h3>Manual Entry</h3>
            <form onSubmit={handleManualSubmit} style={{ display: 'flex', gap: 8 }}>
              <input placeholder="Paste QR code" value={manualCode} onChange={(e) => setManualCode(e.target.value)} style={{ flex: 1, minWidth: 0 }} />
              <button type="submit" style={{ background: '#1A1A1A' }}>Confirm</button>
            </form>
          </div>

          <div style={S.card}>
            <h3>Scan Result</h3>
            {!result && <p style={{ fontSize: 13 }}>{scanning ? 'Waiting for a QR code...' : 'No scan yet. Open the camera or paste a code.'}</p>}
            {result && (
              <>
                {result.ok ? (
                  <>
                    <div style={{ color: '#1E8E4E', fontWeight: 700, fontSize: 15 }}>Order Confirmed ✓</div>
                    <div style={{ marginTop: 10, fontSize: 13, color: '#444', lineHeight: 1.8 }}>
                      <div>Order <strong>#{result.data.order_id}</strong></div>
                      <div>{result.data.fuel_type} · {result.data.liters} L</div>
                      <div style={{ color: ORANGE, fontWeight: 700 }}>₱{result.data.amount}</div>
                    </div>
                  </>
                ) : (
                  <div style={{ color: '#B8340A', fontSize: 13, fontWeight: 600 }}>{result.msg}</div>
                )}
                <button onClick={scanAgain} style={{ marginTop: 14, width: '100%' }}>Scan Another</button>
              </>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}