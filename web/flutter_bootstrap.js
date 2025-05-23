// Create loading indicator
const loading = document.createElement('div');
loading.style.cssText = `
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-family: 'Montserrat', sans-serif;
  font-size: 24px;
  color: #333;
  text-align: center;
  z-index: 9999;
`;
document.body.appendChild(loading);

// Get URL parameters for configuration
const searchParams = new URLSearchParams(window.location.search);
const renderer = searchParams.get('renderer');
const userConfig = {
  renderer: renderer || 'auto',
  assetBase: '/',
  canvasKitBaseUrl: '/canvaskit/',
  canvasKitVariant: 'auto',
  debugShowSemanticNodes: false
};

// Initialize Flutter
_flutter.loader.load({
  config: userConfig,
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      loading.textContent = "Initializing BlinkConnect...";
      const appRunner = await engineInitializer.initializeEngine({
        useColorEmoji: true,
        renderer: userConfig.renderer
      });

      loading.textContent = "Starting BlinkConnect...";
      await appRunner.runApp();
      
      // Remove loading indicator after app starts
      setTimeout(() => {
        loading.remove();
      }, 500);
    } catch (error) {
      loading.textContent = "Error loading BlinkConnect: " + error.message;
      console.error("Failed to initialize Flutter:", error);
    }
  }
}); 