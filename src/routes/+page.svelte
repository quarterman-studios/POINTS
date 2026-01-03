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

<style lang="scss">
	@use '../styles/variables' as *;

	// Global Page Layout
	.page-container {
		max-width: 480px;
		margin: 0 auto;
		padding: $space-lg $space-md;
		min-height: 100vh;
		font-family: $font-stack;
		color: var(--text-primary);
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
		// Uses the NEW variable for proper separation
		margin-bottom: $space-xl;
		padding-top: $space-lg;

		h1 {
			font-family: var(--font-header), sans-serif;
			font-size: 6rem;
			font-weight: $weight-bold;
			margin-bottom: $space-sm;
			letter-spacing: -0.05rem;
			color: var(--text-primary);
		}

		.btn-large {
			width: 30%;
			padding: 1em;
			font-size: 1em;
		}
	}

	.btn-action {
		@extend .btn-primary;
		padding: $space-xs $space-sm;
		font-size: 0.875rem;
		border-radius: $radius-pill;
		cursor: pointer;
	}

	.title-section {
		display: flex;
		justify-content: center;
		margin-bottom: $space-md;
		h2 {
			font-size: 1.5rem;
			font-weight: $weight-bold;
			letter-spacing: -0.05rem;
			color: var(--text-primary);
		}
	}

	// --- DASHBOARD (Private) ---
	.user-dashboard {
		display: grid;
		grid-template-columns: 1fr 1fr auto;
		gap: $space-md;
		// margin-bottom: $space-xl; // Uses NEW variable
		align-items: center;
		background-color: var(--bg-surface);
		padding: $space-md;
		border-radius: $radius-md;
		border: 1px solid var(--border-color);
	}

	.stat-card {
		display: flex;
		flex-direction: column;
		.label {
			font-size: 0.8rem;
			color: var(--text-secondary);
			text-transform: uppercase;
		}
		.value {
			font-size: 1.25rem;
			font-weight: $weight-bold;
			color: var(--text-primary);
		}
	}

	.actions {
		display: flex;
		flex-direction: column;
		gap: $space-xs;
		align-items: flex-end;
	}

	// --- LIST CONTAINER ---
	.list-container {
		position: relative;
		overflow-y: scroll;
		height: 25rem;
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

		transition: all 0.2s;

		&:hover {
			background-color: var(--bg-surface-hover);
		}

		transition: background-color 0.2s;

		&.current-user {
			border-left: 2px solid var(--color-accent);
			background: linear-gradient(90deg, rgba(var(--color-accent), 0.05) 0%, transparent 100%);
		}
	}

	.left-section,
	.right-section {
		display: flex;
		align-items: center;
		gap: $space-sm;
	}

	.rank {
		color: var(--text-secondary);
		width: $space-xl;
		font-variant-numeric: tabular-nums;
		font-size: 1rem;
	}

	.avatar-circle {
		width: $space-xl;
		height: $space-xl;
		border-radius: 50%;
		background-color: var(--bg-surface);
		border: 1px solid var(--border-color);
	}

	.info {
		display: flex;
		flex-direction: column;
		gap: $space-xs;

		.username {
			font-weight: $weight-medium;
			font-size: 1rem;
		}
	}

	.points-value {
		font-weight: var(--weight-medium);
		font-variant-numeric: tabular-nums;
	}
</style>
