import logo from './logo.svg';
import './App.css';

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          REACT_APP_API_URL: { window.ENV?.REACT_APP_API_URL ?? 'Not set'}
          <br/>
          REACT_APP_NAME: { window.ENV?.REACT_APP_NAME ?? 'Default name' }
          <br/>
          REACT_APP_ENV: { window.ENV?.REACT_APP_ENV ?? 'prod' }
          <br/>
          REACT_APP_VERSION: { window.ENV?.REACT_APP_VERSION ?? '1.0.0' }
          <br/>
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
