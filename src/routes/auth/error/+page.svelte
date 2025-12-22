<script lang="ts">
  import { page } from '$app/stores';

  // Grab the message from the URL, or default to generic text
  $: errorMessage = $page.url.searchParams.get('message') || 'An unknown error occurred';
</script>

<div class="error-container">
  <h1>Login Failed</h1>
  
  <div class="error-box">
    <p class="error-text">{errorMessage}</p>
  </div>

  <a href="/" class="retry-btn">Try Logging In Again</a>
</div>

<style>
  .error-container {
    max-width: 400px;
    margin: 4rem auto;
    text-align: center;
    font-family: sans-serif;
  }
  .error-box {
    background: #fff5f5;
    border: 1px solid #fc8181;
    color: #c53030;
    padding: 1rem;
    border-radius: 8px;
    margin: 2rem 0;
  }
  .retry-btn {
    display: inline-block;
    padding: 0.8rem 1.5rem;
    background: #000;
    color: white;
    text-decoration: none;
    border-radius: 6px;
    font-weight: 500;
  }
</style>