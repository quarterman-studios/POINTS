<script lang="ts">
	import '../styles/app.scss';

	import { onMount } from 'svelte';
	import { invalidate } from '$app/navigation';
	import { goto } from '$app/navigation';
	import type { SubmitFunction } from './$types';
	import { enhance } from '$app/forms';
	import { page } from '$app/state';
	import { slide } from 'svelte/transition';

	let { data, children } = $props();
	let { supabase, session } = $derived(data);

	let signoutLoading = $state(false);

	let isSignedIn = $derived(!!session);

	let pageSlug = $derived(page.url.pathname.split('/')[1] || 'home');

	let isOpen = $state(false);

	function toggleMenu() {
		isOpen = !isOpen;
	}

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
		} else if (pageSlug === slug) {
			return 'active';
		}
	};

	// Optional: Close menu if user clicks outside of it
	const handleOutsideClick = (event: MouseEvent) => {
		const target = event.target as HTMLElement;
		// If the click is NOT inside the dropdown or the button, close it
		if (isOpen && !target.closest('.menu-wrapper')) {
			isOpen = false;
		}
	};

	$inspect(pageSlug);
</script>

<svelte:head>
	<title>POINTS</title>
</svelte:head>

<div class="app-container">
	<aside class="mobile-top-nav">
		<div class="logo">"P"</div>
		<div class="nav-footer">
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

			<div class="menu-wrapper">
				<button
					class="nav-btn"
					onclick={toggleMenu}
					aria-label="Toggle menu"
					aria-expanded={isOpen}
				>
					<svg
						width="24"
						height="24"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						stroke-linecap="round"
						stroke-linejoin="round"
					>
						<line x1="3" y1="12" x2="21" y2="12"></line>
						<line x1="3" y1="6" x2="21" y2="6"></line>
						<line x1="3" y1="18" x2="21" y2="18"></line>
					</svg>
				</button>

				{#if isOpen}
					<div class="dropdown" transition:slide={{ duration: 200 }}>
						<ul>
							<li>
								<form method="post" action="?/signout" use:enhance={handleSignOut}>
									<button class="logout">Sign Out</button>
								</form>
							</li>
						</ul>
					</div>
				{/if}
			</div>
		</div>
	</aside>

	<aside class="mobile-bottom-nav">
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
				><path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2" /><circle cx="12" cy="7" r="4" /></svg
			>
		</button>
	</aside>

	<aside class="sidebar">
		<div class="logo">"P"</div>

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
			<div class="menu-wrapper">
				<button
					class="nav-btn"
					onclick={toggleMenu}
					aria-label="Toggle menu"
					aria-expanded={isOpen}
				>
					<svg
						width="24"
						height="24"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						stroke-linecap="round"
						stroke-linejoin="round"
					>
						<line x1="3" y1="12" x2="21" y2="12"></line>
						<line x1="3" y1="6" x2="21" y2="6"></line>
						<line x1="3" y1="18" x2="21" y2="18"></line>
					</svg>
				</button>

				{#if isOpen}
					<div class="dropdown" transition:slide={{ duration: 200, axis: 'x' }}>
						<ul>
							<li>
								<form method="post" action="?/signout" use:enhance={handleSignOut}>
									<button class="logout">Sign Out</button>
								</form>
							</li>
						</ul>
					</div>
				{/if}
			</div>
		</div>
	</aside>

	<main class="main-content">
		{@render children()}
	</main>
</div>

<svelte:window onclick={handleOutsideClick} />

<style lang="scss">
	@use '../styles/variables' as *;
	@use '../styles/mixins' as *;

	:global(body) {
		overflow: hidden;
		margin: 0;
	}

	// --- LAYOUT GRID ---
	.app-container {
		display: grid;
		height: 100dvh; // Dynamic viewport height
		width: 100%;
		background-color: var(--bg-app);
		color: var(--text-primary);
		overflow: hidden;

		// --- MOBILE LAYOUT (Default) ---
		// 1 Column
		// Row 1: Content (1fr = takes remaining space)
		// Row 2: Navbar (auto = takes its natural height)
		grid-template-columns: 1fr;
		grid-template-rows: 50px 1fr auto;

		// This is the magic: We use grid areas to reorder the HTML visually
		// Sidebar is 1st in HTML, but we want it at the bottom visually
		grid-template-areas:
			'mobile-top-nav'
			'content'
			'mobile-bottom-nav';

		// --- TABLET/DESKTOP LAYOUT ---
		@include respond-to('tablet') {
			// Col 1: Navbar (80px)
			// Col 2: Content (Remaining space)
			grid-template-columns: 80px 1fr;
			grid-template-rows: 1fr;

			grid-template-areas: 'nav content';
		}
	}

	// --- MAIN CONTENT AREA ---
	.main-content {
		grid-area: content; // Assign to the "content" grid slot
		position: relative;
		overflow: hidden; // Clip overflow so the wrapper handles scrolling
		min-height: 0; // Crucial for nested flex/grid scrolling
		padding: $space-md;
	}

	.nav-btn {
		background: transparent;
		border: none;
		color: var(--text-secondary);
		cursor: pointer;
		padding: $space-md;
		border-radius: $radius-sm;
		transition: all 0.2s;
		display: flex;
		align-items: center;
		justify-content: center;

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

		@include respond-to('tablet') {
			flex: none;
			width: auto;
		}
	}

	.mobile-top-nav {
		grid-area: mobile-top-nav;

		background-color: var(--bg-app);
		border-bottom: 1px solid var(--border-color);
		z-index: 10;

		// MOBILE FLEX LAYOUT (Row)
		display: flex;
		flex-direction: row;
		justify-content: space-between;
		align-items: center;

		padding: $space-md;

		.nav-btn {
			@extend .nav-btn;
			flex: 0;
		}

		.nav-footer {
			display: flex;
			align-items: center;
		}

		@include respond-to('tablet') {
			display: none;
		}
	}

	.menu-wrapper {
		position: relative;
		display: inline-block;
	}

	.mobile-bottom-nav {
		grid-area: mobile-bottom-nav;

		background-color: var(--bg-surface);
		border-right: none;
		border-top: 1px solid var(--border-color);
		z-index: 10;

		// MOBILE FLEX LAYOUT (Row)
		display: flex;
		flex-direction: row;
		align-items: center;
		justify-content: space-between;

		// No 'position: fixed' needed! The grid places it at the bottom.
		// We just ensure it spans the full width of its grid cell.
		width: 100%;

		// Handle iPhone Home Bar
		padding-bottom: env(safe-area-inset-bottom, $space-sm);

		.nav-btn {
			@extend .nav-btn;
			flex: 1;
		}

		@include respond-to('tablet') {
			display: none;
		}
	}

	.logo {
		font-family: var(--font-header), sans-serif;
		font-weight: $weight-bold;
		font-size: 1.5rem;
		color: var(--color-accent);

		@include respond-to('tablet') {
			display: block;
			margin-bottom: $space-2xl;
		}
	}

	.dropdown {
		position: absolute;
		top: 100%; // Push it to the bottom of the button
		right: 0; // Align to the right edge of the button
		width: 200px; // Or generic width

		background-color: var(--bg-surface, white);
		border: 1px solid var(--border-color, #eee);
		border-radius: 8px;
		box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);

		z-index: 1000; // Ensure it floats above content
		margin-top: 8px; // Little gap between button and menu
		overflow: hidden; // Keeps borders clean

		ul {
			list-style: none;
			padding: 0;
			margin: 0;
		}

		li {
			border-bottom: 1px solid var(--border-color, #eee);

			&:last-child {
				border-bottom: none;
			}

			&.divider {
				height: 4px;
				background-color: #f5f5f5;
				border: none;
			}
		}

		a,
		button.logout {
			display: block;
			width: 100%;
			padding: 12px 16px;
			text-decoration: none;
			color: var(--text-primary, #333);
			text-align: left;
			background: none;
			border: none;
			font-size: 1rem;
			cursor: pointer;
			transition: background 0.2s;

			&:hover {
				background-color: var(--bg-surface-hover, #f9f9f9);
			}
		}

		.logout {
			color: var(--color-danger, red);
		}
	}

	// --- SIDEBAR / NAVBAR ---
	.sidebar {
		display: none;
		grid-area: nav; // Assign to the "nav" grid slot

		background-color: var(--bg-surface);
		border-right: none;
		border-top: 1px solid var(--border-color);
		z-index: 10;

		// TABLET/DESKTOP OVERRIDE (Column)
		@include respond-to('tablet') {
			display: flex;
			flex-direction: column;
			align-items: center;

			border-top: none;
			border-right: 1px solid var(--border-color);

			padding: $space-lg 0;
			height: 100%; // Fill the height of the grid cell
		}

		.nav-links {
			display: flex;
			justify-content: space-around;
			flex: 1;

			flex-direction: column; // Desktop Column
			justify-content: center;
			gap: $space-lg;
		}

		.sidebar-footer {
			@include respond-to('tablet') {
				margin-left: 0;
				margin-top: auto;
			}
		}

		.dropdown {
			@include respond-to('tablet') {
				right: auto;
				left: 100%; // Align to the left edge of the button
				top: 0; // Align to the top of the button
				margin-top: 0;
				margin-left: $space-md; // Little gap between button and menu
			}
		}
	}
</style>
