<script lang="ts">
	import { goto, invalidateAll } from '$app/navigation';
	import { onMount, tick } from 'svelte';

	let { data } = $props();
	let { session, leaderboard, userProfile, leaderBoardSize, supabase } = $derived(data);

	// let loading = $state(false);
	let signedIn = $derived(!!session);

	let minRow: number | null = $state(null);
	let maxRow: number | null = $state(null);

	let searchDisplay: boolean = $state(false);
	let searchInput: HTMLInputElement | undefined = $state();
	let searchResults: any[] = $state([]);

	let listContainer: HTMLElement | undefined = $state();
	let topSentinel: HTMLElement | undefined = $state();
	let bottomSentinel: HTMLElement | undefined = $state();

	// Loading flags to prevent double-fetching
	let loadingUp = $state(false);
	let loadingDown = $state(false);

	$effect(() => {
		if (leaderboard) {
			minRow = leaderboard[0].row_number;
			maxRow = leaderboard[leaderboard.length - 1].row_number;
		}
	});

	let loadLimit = 5;

	// --- FETCH FUNCTIONS ---
	async function loadMoreBelow() {
		if (leaderBoardSize && maxRow) if (loadingDown || maxRow >= leaderBoardSize) return;

		loadingDown = true;

		if (supabase && leaderboard && leaderBoardSize) {
			const { data: newRows } = await supabase
				.from('leaderboard')
				.select('*')
				.gt('row_number', maxRow) // Get rows larger than current max
				.order('row_number', { ascending: true })
				.limit(loadLimit);

			if (newRows && newRows.length > 0 && maxRow) {
				leaderboard = [...leaderboard, ...newRows];
				maxRow += loadLimit;
			}
		}

		loadingDown = false;
	}

	async function loadMoreAbove() {
		// Stop if we are already at rank 1
		if (minRow) if (loadingUp || minRow <= 1) return;

		loadingUp = true;

		if (listContainer && supabase) {
			// capture scroll height BEFORE adding content
			const oldHeight = listContainer.scrollHeight;
			const oldScrollTop = listContainer.scrollTop;

			// Query: We want the immediate predecessors (e.g. 49, 48, 47 if min is 50)
			// So we order DESCENDING to get the ones closest to us, then reverse them back.
			const { data: newRows } = await supabase
				.from('leaderboard')
				.select('*')
				.lt('row_number', minRow)
				.order('row_number', { ascending: false }) // IMPORTANT: Get closest neighbors first
				.limit(loadLimit);

			if (newRows && newRows.length && leaderboard && minRow) {
				// Reverse them so they are in 1,2,3 order before prepending
				const orderedRows = newRows.reverse();
				leaderboard = [...orderedRows, ...leaderboard];

				minRow -= loadLimit;

				// MAGIC FIX: Restore scroll position
				await tick(); // Wait for DOM to update
				const newHeight = listContainer.scrollHeight;
				// Shift scroll down by the amount of content we just added
				listContainer.scrollTop = oldScrollTop + (newHeight - oldHeight);
			}
		}
		loadingUp = false;
	}

	const findUser = async () => {
		if (!supabase) return;

		const usernameInput = (document.querySelector('.search-bar input') as HTMLInputElement).value;

		const { data: userData, error } = await supabase
			.from('leaderboard')
			.select('*')
			.ilike('username', `%${usernameInput}%`)
			.order('row_number', { ascending: true })
			.limit(20);

		if (error || !userData) {
			alert('User not found');
			return;
		}

		searchResults = userData;
	};

	// --- OBSERVER SETUP ---

	onMount(() => {
		const observer = new IntersectionObserver(
			(entries) => {
				entries.forEach((entry) => {
					if (!entry.isIntersecting) return;

					if (entry.target === topSentinel) {
						loadMoreAbove();
					} else if (entry.target === bottomSentinel) {
						loadMoreBelow();
					}
				});
			},
			{
				root: listContainer, // Observe relative to the scrolling box
				threshold: 0.1, // Trigger when 10% visible
				rootMargin: '100px' // Pre-load before user actually hits the edge
			}
		);

		if (topSentinel) observer.observe(topSentinel);
		if (bottomSentinel) observer.observe(bottomSentinel);

		return () => observer.disconnect();
	});

	const handleRefresh = async () => {
		window.location.reload();
	};
</script>

<div class="scroll-wrapper">
	<div class="page-container">
		{#if !signedIn}
			<section class="hero">
				<h1>"POINTS"</h1>

				<button class="btn-primary btn-large" onclick={() => goto('/login')}> SIGN IN </button>
			</section>
		{/if}

		{#if signedIn}
			<section class="title-section">
				<h2>LEADERBOARD</h2>
				<p class="label">Steal points from other players</p>
			</section>
			<section class="user-dashboard">
				<div class="stat-card">
					<span class="label">Rank</span>
					<span class="value">#{userProfile?.rank ?? '-'}</span>
				</div>
				<div class="stat-card">
					<span class="label">Points</span>
					<span class="value">{userProfile?.points ?? 0}</span>
				</div>
				<div class="actions">
					<button class="btn-text" onclick={() => goto('/profile')}>Profile</button>
				</div>
			</section>
		{/if}

		<section class="filter-section">
			<button class="btn-text" onclick={() => (searchDisplay = true)}>SEARCH</button>
			<button class="btn-text" onclick={handleRefresh}>REFRESH</button>
		</section>

		<form class="search-bar" style={searchDisplay ? 'display: flex' : 'display: none'}>
			<input type="text" placeholder="SEARCH" bind:value={searchInput} />
			<button aria-label="submit" class="btn-text" onclick={findUser}>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					width="24"
					height="24"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
					stroke-width="2"
					stroke-linecap="round"
					stroke-linejoin="round"
				>
					<path d="M20 6L9 17l-5-5" />
				</svg>
			</button>
			<button
				aria-label="cross"
				class="btn-text"
				onclick={() => {
					searchDisplay = false;
					searchInput = undefined;
					searchResults = [];
				}}
			>
				<svg
					xmlns="http://www.w3.org/2000/svg"
					width="24"
					height="24"
					fill="none"
					viewBox="0 0 24 24"
					stroke="currentColor"
					stroke-width="2"
					stroke-linecap="round"
					stroke-linejoin="round"
				>
					<path d="M18 6L6 18M6 6l12 12" />
				</svg></button
			>
		</form>

		{#if searchDisplay}
			<section class="search-container">
				{#if searchResults.length === 0}
					<div style="text-align: center; margin-top: 2rem;">
						<p>No results found.</p>
					</div>
				{:else}
					<div class="rows">
						{#each searchResults as player}
							{@const isMe = userProfile?.username === player.username}

							<div class="row {isMe ? 'current-user' : ''}">
								<div class="left-section">
									<span class="rank">#{player.rank}</span>
									<div class="avatar-circle"></div>

									<div class="info">
										<span class="username">{player.username}</span>
									</div>
								</div>

								<div class="right-section">
									<span class="points-value">{player.points}</span>
									{#if signedIn && !isMe && player.points != 0}
										<button class="btn-action">STEAL</button>
									{/if}
								</div>
							</div>
						{/each}
					</div>
				{/if}
			</section>
		{/if}

		{#if !searchDisplay}
			<section class="list-container" bind:this={listContainer}>
				{#if minRow && minRow > 1 && !searchDisplay}
					<div bind:this={topSentinel}>
						{#if loadingUp}
							<span>Loading...</span>
						{/if}
					</div>
				{/if}

				<div class="rows">
					{#each leaderboard as player}
						{@const isMe = userProfile?.username === player.username}

						<div class="row {isMe ? 'current-user' : ''} {signedIn ? 'can-hover' : ''}">
							<div class="left-section">
								<span class="rank">#{player.rank}</span>
								<div class="avatar-circle"></div>

								<div class="info">
									<span class="username">{player.username}</span>
								</div>
							</div>

							<div class="right-section">
								<span class="points-value">{player.points}</span>
								{#if signedIn && !isMe && player.points != 0}
									<button class="btn-action">STEAL</button>
								{/if}
							</div>
						</div>
					{/each}
				</div>

				{#if maxRow && leaderBoardSize && maxRow < leaderBoardSize && !searchDisplay}
					<div bind:this={bottomSentinel}>
						{#if loadingDown}
							<span>Loading...</span>
						{/if}
					</div>
				{/if}
			</section>
		{/if}
	</div>
</div>

<style lang="scss">
	// Import variables AND the new mixins file
	@use '../styles/variables' as *;
	@use '../styles/mixins' as *;

	// --- GLOBAL PAGE LAYOUT ---
	.page-container {
		width: 100%; // Default: take up full width on mobile
		padding: $space-md; // Default: smaller padding for mobile
		min-height: 100vh;
		font-family: $font-stack;
		color: var(--text-primary);
		margin: 0 auto;

		// On Tablet/Desktop: Restrict width and increase padding
		@include respond-to('tablet') {
			max-width: calc($width-max / 16 * 10);
			padding: $space-lg;
		}
	}

	// Search BAR
	.search-bar {
		justify-content: center;
		align-items: center;
		background-color: white;
		margin: $space-sm;

		input {
			width: 60vw;
			font-family: $font-stack;
		}

		button {
			display: flex;
			flex: 1;
		}
	}

	// Filter Section
	.filter-section {
		display: flex;
		flex-direction: row;
		justify-content: space-between;
		margin: $space-xs;
	}

	.search-container {
		overflow-y: scroll;
		height: 55vh;
	}

	// --- HERO SECTION (Public) ---
	.hero {
		text-align: center;
		margin-bottom: $space-xl;

		h1 {
			font-family: var(--font-header), sans-serif;
			font-weight: $weight-bold;
			letter-spacing: -0.05rem;
			color: var(--text-primary);
			margin-bottom: $space-md;

			// RESPONSIVE TYPOGRAPHY
			font-size: 3.5rem; // Mobile size
			line-height: 1.1;

			@include respond-to('tablet') {
				font-size: 6rem; // Original massive size for desktop
			}
		}

		// RESPONSIVE BUTTON
		.btn-large {
			width: 100%; // Mobile: Full width for easy thumb reach
			padding: 1em;
			font-size: 1em;

			@include respond-to('tablet') {
				width: auto; // Desktop: Let content define width
				min-width: 200px;
			}
		}
	}

	.btn-action {
		@extend .btn-primary;
		padding: $space-xs $space-sm;
		font-size: 0.75rem; // Slightly smaller on mobile
		border-radius: $radius-pill;
		cursor: pointer;
		white-space: nowrap; // Prevent button text wrapping

		@include respond-to('tablet') {
			font-size: 0.875rem;
		}
	}

	.title-section {
		display: flex;
		flex-direction: column;
		align-items: center;
		margin-bottom: $space-md;
		text-align: center;

		h2 {
			font-size: 1.25rem;
			font-weight: $weight-bold;
			letter-spacing: -0.05rem;
			color: var(--text-primary);
			margin-top: $space-sm;

			@include respond-to('tablet') {
				font-size: 1.5rem;
			}
		}

		.label {
			font-size: 0.75rem;
			color: var(--text-secondary);
			text-transform: uppercase;

			@include respond-to('tablet') {
				font-size: 0.875rem;
			}
		}
	}

	// --- DASHBOARD (Private) ---
	.user-dashboard {
		position: sticky;
		position: -webkit-sticky; // For Safari support

		top: 0;

		z-index: 10; // Ensure it stays above other content
		// MOBILE DEFAULT: Stack vertically
		display: flex;
		flex-direction: row;
		justify-content: space-around;

		margin-bottom: $space-xl;
		background-color: var(--bg-surface);
		padding: $space-md;
		border-radius: $radius-md;
		border: 1px solid var(--border-color);

		// TABLET+: Switch to Grid
		@include respond-to('tablet') {
			display: grid;
			grid-template-columns: 1fr 1fr auto;
			align-items: center;
		}
	}

	.stat-card {
		display: flex;
		flex-direction: column;
		// Mobile: Center text for impact
		align-items: center;

		.label {
			font-size: 0.8rem;
			color: var(--text-secondary);
			text-transform: uppercase;
		}
		.value {
			font-size: 1.3rem; // Bigger numbers are good on mobile
			font-weight: $weight-bold;
			color: var(--text-primary);
		}

		@include respond-to('tablet') {
			font-size: 1.5rem;
			align-items: flex-start; // Reset to left align on desktop
		}
	}

	// --- LIST CONTAINER ---
	.list-container {
		position: relative;

		@include respond-to('tablet') {
			height: 55vh; // Fixed height for scrollable area
			overflow-y: auto;
		}
	}

	// --- THE ROW ---
	.row {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: $space-sm;
		border: 1px solid var(--border-color);
		border-radius: $radius-sm;
		margin-bottom: $space-sm;
		gap: $space-sm; // Ensure space between left/right sections
		transition: all 0.2s;

		&.current-user {
			border-left: 2px solid var(--color-accent);
			background: linear-gradient(90deg, rgba(var(--color-accent), 0.05) 0%, transparent 100%);
		}
	}

	.can-hover {
		&:hover {
			background-color: var(--bg-surface-hover);
		}
	}

	.left-section {
		display: flex;
		align-items: center;
		gap: $space-sm;
		min-width: 0; // Fixes flexbox text overflow issues
	}

	.right-section {
		display: flex;
		align-items: center;
		gap: $space-sm;
		flex-shrink: 0; // Prevents points/button from squishing
	}

	.rank {
		color: var(--text-secondary);
		width: 1.5rem; // Reduce width slightly on mobile
		font-variant-numeric: tabular-nums;
		font-size: 0.875rem;

		@include respond-to('tablet') {
			width: $space-xl;
			font-size: 1rem;
		}
	}

	.avatar-circle {
		// Mobile: Smaller avatar
		width: 2rem;
		height: 2rem;
		border-radius: 50%;
		background-color: var(--bg-surface);
		border: 1px solid var(--border-color);
		flex-shrink: 0;

		@include respond-to('tablet') {
			width: $space-xl; // 2.5rem
			height: $space-xl;
		}
	}

	.info {
		display: flex;
		flex-direction: column;
		gap: 0;
		overflow: hidden; // Handle long usernames

		.username {
			font-weight: $weight-medium;
			font-size: 0.875rem;
			white-space: nowrap;
			overflow: hidden;
			text-overflow: ellipsis; // "Userna..."

			@include respond-to('tablet') {
				font-size: 1rem;
			}
		}
	}

	.points-value {
		font-weight: $weight-medium; // corrected var usage
		font-variant-numeric: tabular-nums;
		font-size: 0.875rem;

		@include respond-to('tablet') {
			font-size: 1rem;
		}
	}

	// Helper button text style
	.btn-text {
		font-family: $font-stack;
		background: none;
		border: none;
		color: var(--text-secondary);
		font-size: 0.875rem;
		cursor: pointer;

		&:hover {
			color: var(--text-primary);
			text-decoration: underline;
		}
	}
</style>
