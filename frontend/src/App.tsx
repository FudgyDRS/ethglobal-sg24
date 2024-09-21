import { useState } from 'react';
import reactLogo from './assets/react.svg';
import viteLogo from '/vite.svg';
import './App.css';
import { execHaloCmdWeb } from '@arx-research/libhalo/api/web';

import { createAppKit, useAppKit, useAppKitEvents, useAppKitState, useAppKitTheme } from '@reown/appkit/react';
import { EthersAdapter } from '@reown/appkit-adapter-ethers';
import { mainnet, arbitrum } from '@reown/appkit/networks';
import { ToastContainer, toast } from 'react-toastify';
import 'react-toastify/dist/ReactToastify.css';

// const projectId = import.meta.env.VITE_PROJECT_ID
// if (!projectId) {
//   throw new Error('VITE_PROJECT_ID is not set')
// }

// 2. Set chains
const networks = [mainnet, arbitrum];

const ethersAdapter = new EthersAdapter();

// 3. Create modal
const projectId = '1';
createAppKit({
  adapters: [ethersAdapter],
  networks,
  projectId,
  features: {
    analytics: true,
  },
  themeMode: 'light',
  themeVariables: {
    '--w3m-color-mix': '#00DCFF',
    '--w3m-color-mix-strength': 20,
  },
});

function App() {
  const [count, setCount] = useState(0);
  const modal = useAppKit();
  const state = useAppKitState();
  const { themeMode, themeVariables, setThemeMode } = useAppKitTheme();
  const events = useAppKitEvents();
  const [statusText, setStatusText] = useState('Click on the button');

  const btnClick = async () =>  {
    let command = {
      name: 'sign',
      keyNo: 1,
      message: '010203',
    };

    let res;

    try {
      // --- request NFC command execution ---
      res = await execHaloCmdWeb(command);
      // the command has succeeded, display the result to the user
      setStatusText(JSON.stringify(res, null, 4));
    } catch (e) {
      // the command has failed, display error to the user
      setStatusText('Error: ' + String(e));
    }
  }

  return (
    <>
      <w3m-button />
      <w3m-network-button />
      <w3m-connect-button />
      <w3m-account-button />

      <button onClick={() => modal.open()}>Connect Wallet</button>
      <button onClick={() => modal.open({ view: 'Networks' })}>Choose Network</button>
      <button onClick={() => setThemeMode(themeMode === 'dark' ? 'light' : 'dark')}>Toggle Theme Mode</button>

      <div>
        <pre style={{ fontSize: 12, textAlign: 'left' }}>{statusText}</pre>
        <button onClick={() => btnClick()}>Sign message 010203 using key #1</button>
      </div>
      <ToastContainer />
    </>
  );
}

export default App;
