import { useEffect, useState } from 'react';
import api from '../api/client';
import { useAuth } from '../context/AuthContext';

export default function StationServices() {
  const { staff } = useAuth();
  const [stations, setStations] = useState([]);
  const [prices, setPrices] = useState([]);

  useEffect(() => {
    api.get('/staff/stations').then((r) => setStations(r.data.data.stations));
    api.get('/staff/stations/compare').then((r) => setPrices(r.data.data.prices));
  }, []);

  const myStation = stations.find((s) => s.station_id === staff?.station_id);

  return (
    <div>
      <h2>Station Services</h2>
      <p>Your station's location and a live price comparison across all partners</p>

      {myStation && (
        <div className="card" style={{ marginTop: 20, padding: 0, overflow: 'hidden' }}>
          <div style={{ padding: 20 }}><h3 style={{ margin: 0 }}>{myStation.name}</h3></div>
          <iframe title="map" width="100%" height="260" style={{ border: 0, display: 'block' }}
            src={`https://maps.google.com/maps?q=${myStation.latitude},${myStation.longitude}&z=15&output=embed`} />
        </div>
      )}

      <div className="card" style={{ marginTop: 20 }}>
        <h3>Compare Fuel Prices — All Stations</h3>
        <table style={{ boxShadow: 'none' }}>
          <thead><tr><th>Station</th><th>Brand</th><th>Fuel Type</th><th>Price</th><th>Available</th></tr></thead>
          <tbody>
            {prices.map((p) => (
              <tr key={p.price_id} style={{ background: p.station_id === staff?.station_id ? '#FFF8F5' : 'transparent' }}>
                <td>{p.station_name}</td><td>{p.fuel_brand}</td><td>{p.fuel_type}</td><td>₱{p.price}</td>
                <td><span style={{ color: p.availability ? '#2E7D32' : '#D8232A', fontWeight: 600 }}>{p.availability ? 'Yes' : 'No'}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}