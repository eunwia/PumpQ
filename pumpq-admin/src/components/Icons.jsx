const stroke = { fill: 'none', stroke: 'currentColor', strokeWidth: 1.8, strokeLinecap: 'round', strokeLinejoin: 'round' };
const S = (p) => <svg width="18" height="18" viewBox="0 0 24 24" {...stroke}>{p}</svg>;

export const IconHome = () => S(<path d="M3 11l9-8 9 8M5 10v10h5v-6h4v6h5V10" />);
export const IconUser = () => S(<><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4 4-6 8-6s8 2 8 6" /></>);
export const IconFuel = () => S(<><path d="M4 21V6a2 2 0 012-2h6a2 2 0 012 2v15" /><path d="M4 21h10" /><path d="M14 9h2l3 3v6a1 1 0 01-2 0v-2l-3-3" /></>);
export const IconMap = () => S(<path d="M9 4l-6 2v14l6-2 6 2 6-2V4l-6 2-6-2z M9 4v14 M15 6v14" />);
export const IconTag = () => S(<><path d="M20 10l-9-9H4v7l9 9z" /><circle cx="9" cy="9" r="1.5" /></>);
export const IconReceipt = () => S(<><path d="M6 2h12v20l-3-2-3 2-3-2-3 2V2z" /><path d="M9 7h6M9 11h6M9 15h3" /></>);
export const IconBell = () => S(<><path d="M18 8a6 6 0 10-12 0c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.7 21a2 2 0 01-3.4 0" /></>);
export const IconChart = () => S(<><path d="M4 20V10M10 20V4M16 20v-7M22 20H2" /></>);
export const IconLogout = () => S(<><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" /><path d="M16 17l5-5-5-5M21 12H9" /></>);