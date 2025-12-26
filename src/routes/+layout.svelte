<script lang="ts">
	import '../styles/app.scss';

	import { onMount } from 'svelte';
	import { invalidate } from '$app/navigation';
	import { goto } from '$app/navigation';
	import type { SubmitFunction } from './$types';
	import { enhance } from '$app/forms';
	import { page } from '$app/stores';

	let { data, children } = $props();
	let { supabase, session } = $derived(data);

	let signoutLoading = $state(false);

	let isSignedIn = $derived(!!session);

	let pageSlug = $derived($page.url.pathname.split('/')[1] || 'home');

	onMount(() => {
		const { data } = supabase.auth.onAuthStateChange((event, _session) => {
			if (_session?.expires_at !== session?.expires_at) {
				invalidate('supabase:auth');
			}
		});
	});

	const handleSignOut: SubmitFunction = () => {
		signoutLoading = true;
		return async ({ update }) => {
			signoutLoading = false;
			update();
		};
	};

	const handleNotifications = () => {
		if (!isSignedIn) {
			goto('/login');
		} else {
			alert('Notifications feature coming soon!');
		}
	};

	const handleProfile = () => {
		if (!isSignedIn) {
			goto('/login');
		} else {
			goto('/profile');
		}
	};

	const isActive = (slug: string) => {
		if (pageSlug === 'home' && slug === 'home') {
			return 'active';
		} else
		if (pageSlug === slug) {
			return 'active';
		}
	};

	$inspect(pageSlug)
	
</script>

<svelte:head>
	<title>POINTS</title>
</svelte:head>

<div class="app-container">
	<aside class="sidebar">
		<div class="logo">P.</div>

		<nav class="nav-links">
			<button class={`nav-btn ${isActive('home')}`} onclick={() => goto('/')} aria-label="Home">
				<svg
					xmlns="http://www.w3.org/2000/svg"
					width="24"
					height="24"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
					stroke-linecap="round"
					stroke-linejoin="round"
					><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline
						points="9 22 9 12 15 12 15 22"
					/></svg
				>
			</button>
			<button class={`nav-btn ${isActive('profile')}`} aria-label="Profile" onclick={handleProfile}>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					width="24"
					height="24"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
					stroke-linecap="round"
					stroke-linejoin="round"
					><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" /><circle
						cx="12"
						cy="7"
						r="4"
					/></svg
				>
			</button>
			<button
				class={`nav-btn ${isActive('notifications')}`}
				aria-label="Notifications"
				onclick={handleNotifications}
			>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					width="24"
					height="24"
					viewBox="0 0 24 24"
					fill="none"
					stroke="currentColor"
					stroke-width="2"
					stroke-linecap="round"
					stroke-linejoin="round"
					><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9" /><path
						d="M10.3 21a1.94 1.94 0 0 0 3.4 0"
					/></svg
				>
			</button>
		</nav>

		<div class="sidebar-footer">
			<form method="post" action="?/signout" use:enhance={handleSignOut}>
				<button class="nav-btn danger" disabled={signoutLoading} aria-label="Sign Out">
					{#if signoutLoading}
						...
					{:else}
						<svg
							xmlns="http://www.w3.org/2000/svg"
							width="24"
							height="24"
							viewBox="0 0 24 24"
							fill="none"
							stroke="currentColor"
							stroke-width="2"
							stroke-linecap="round"
							stroke-linejoin="round"
							><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline
								points="16 17 21 12 16 7"
							/><line x1="21" x2="9" y1="12" y2="12" /></svg
						>
					{/if}
				</button>
			</form>
		</div>
	</aside>
	<main class="main-content">
		{@render children()}
	</main>
</div>

<style lang="scss">
	@use '../styles/variables' as *;

	:global(body) {
		overflow: hidden;
		margin: 0;
	}

	// --- LAYOUT GRID ---
	.app-container {
		display: grid;
		grid-template-columns: 80px 1fr;
		height: 100vh; // Exact viewport height
		width: 100%; // Avoids 100vw horizontal scrollbar issue
		background-color: var(--bg-app);
		color: var(--text-primary);
		overflow: hidden; // Strict clip
	}

	// --- SIDEBAR ---
	.sidebar {
		background-color: var(--bg-surface);
		border-right: 1px solid var(--border-color);
		display: flex;
		flex-direction: column;
		align-items: center;
		padding: $space-lg 0;
		z-index: 10;
		height: 95vh; // Full height

		.logo {
			font-weight: $weight-bold;
			font-size: 24px;
			margin-bottom: $space-2xl;
			color: var(--color-accent);
		}

		.nav-links {
			display: flex;
			flex-direction: column;
			gap: $space-lg;
			flex: 1;
		}

		.nav-btn {
			background: transparent;
			border: none;
			color: var(--text-secondary);
			cursor: pointer;
			padding: 10px;
			border-radius: $radius-sm;
			transition: all 0.2s;

			&:hover {
				color: var(--text-primary);
				background-color: var(--bg-surface-hover);
			}

			&.active {
				color: var(--color-accent);
				background-color: rgba(var(--color-accent), 0.1);
			}

			&.danger:hover {
				color: var(--color-danger);
				background-color: rgba(var(--color-danger), 0.1);
			}
		}
	}
</style>
