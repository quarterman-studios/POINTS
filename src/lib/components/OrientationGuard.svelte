<div class="orientation-lock">
  <div class="content">
    <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <rect x="5" y="2" width="14" height="20" rx="2" ry="2"></rect>
      <path d="M12 18h.01"></path>
    </svg>
    <h2>Please Rotate Your Device</h2>
    <p>This game is designed for Portrait Mode.</p>
  </div>
</div>

<style lang="scss">
  .orientation-lock {
    // 1. Hidden by default (in Portrait)
    display: none; 
    
    // 2. Full Screen Overlay
    position: fixed;
    top: 0;
    left: 0;
    width: 100vw;
    height: 100vh;
    background-color: #1a1a1a; // Dark background
    z-index: 99999; // Sit on top of EVERYTHING
    color: white;
    
    // 3. Center the message
    align-items: center;
    justify-content: center;
    text-align: center;

    .content {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 1rem;
    }

    svg {
      animation: rotate-phone 2s infinite ease-in-out;
    }
  }

  // --- THE LOGIC ---
  // If the device is in Landscape AND it's a mobile device (width < height generally or specific max-height)
  @media screen and (orientation: landscape) and (max-height: 600px) {
    .orientation-lock {
      display: flex; // Show the blocker
    }
  }

  // Animation to prompt user
  @keyframes rotate-phone {
    0% { transform: rotate(-90deg); }
    50% { transform: rotate(0deg); }
    100% { transform: rotate(-90deg); }
  }
</style>