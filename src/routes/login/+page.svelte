<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData, PageData, SubmitFunction } from './$types';
	import GoogleButton from '$lib/components/GoogleButton.svelte';
	import { goto } from '$app/navigation';

	interface Props {
		form: ActionData;
		data: PageData;
	}

	let loading = $state(false);
	let googleLoading = $state(false);

	let { form, data }: Props = $props();

	const handleSubmit: SubmitFunction = () => {
		loading = true;
		return async ({ update }) => {
			update();
			loading = false;
		};
	};

	const handleGoogleSignIn = async () => {
		googleLoading = true;
		const { error } = await data.supabase.auth.signInWithOAuth({
			provider: 'google',
			options: {
				redirectTo: `${window.location.origin}/auth/confirm`
			}
		});

		if (error) {
			console.error('Error during Google sign-in:', error);
			loading = false;
		}
	};
</script>

<div class="page-wrapper">
	<div class="login-card">
		<header>
			<h1>Welcome Back</h1>
			<p class="subtitle">Sign in to access the arena.</p>
		</header>

		<form method="POST" action="?/magic-link-signin" use:enhance={handleSubmit}>
			<div class="input-group">
				<label for="email">Email Address</label>
				<input
					name="email"
					id="email"
					type="email"
					placeholder="neo@matrix.com"
					autocomplete="email"
				/>
			</div>

			{#if form?.message || form?.errors?.email}
				<p class="error-message">
					{form?.message || form?.errors?.email}
				</p>
			{/if}

			<button class="btn-primary" aria-label="Submit Details">
				{loading ? 'Sending Link...' : 'Send Magic Link'}
			</button>

			<div class="divider">
				<span>Or continue with</span>
			</div>

			<div class="google-wrapper">
				<GoogleButton loading={googleLoading} onClick={handleGoogleSignIn} />
			</div>
		</form>

		<button class="btn-text" onclick={() => goto('/')}> ← Back to Leaderboard </button>
	</div>
</div>

<style lang="scss">
	@use '../../styles/variables' as *;

	// Center the card on the screen (The "Void" feel)
	.page-wrapper {
		min-height: 100vh;
		display: flex;
		align-items: center;
		justify-content: center;
		background-color: var(--bg-app);
		padding: $space-md;
	}

	.login-card {
		width: 100%;
		max-width: 400px;
		background-color: var(--bg-surface);
		border: 1px solid var(--border-color);
		border-radius: $radius-md;
		padding: $space-xl;
		display: flex;
		flex-direction: column;
		gap: $space-lg;
	}

	header {
		text-align: center;

		h1 {
			font-size: 24px;
			font-weight: $weight-bold;
			color: var(--text-primary);
			margin-bottom: $space-xs;
			letter-spacing: -0.5px;
		}

		.subtitle {
			color: var(--text-secondary);
			font-size: 14px;
		}
	}

	form {
		display: flex;
		flex-direction: column;
		gap: $space-md;
	}

	.input-group {
		display: flex;
		flex-direction: column;
		gap: 6px;

		label {
			font-size: 12px;
			text-transform: uppercase;
			color: var(--text-secondary);
			letter-spacing: 0.5px;
			font-weight: $weight-medium;
		}

		input {
			background-color: var(--bg-app); // Pure black input background
			border: 1px solid var(--border-color);
			color: var(--text-primary);
			padding: 12px;
			border-radius: $radius-sm;
			font-size: 14px;
			transition: border-color 0.2s;

			&::placeholder {
				color: var(--text-muted);
			}

			&:focus {
				outline: none;
				border-color: var(--color-accent); // Green border on focus
			}
		}
	}

	.btn-primary {
		margin-top: $space-sm;
		background-color: var(--color-accent);
		color: var(--color-accent-text); // Black text on green button
		padding: 12px;
		border-radius: $radius-sm;
		font-weight: $weight-bold;
		font-size: 14px;
		border: none;
		cursor: pointer;
		transition: filter 0.2s;

		&:hover {
			filter: brightness(1.1);
		}
	}

	.divider {
		display: flex;
		align-items: center;
		text-align: center;
		margin: $space-xs 0;
		color: var(--text-secondary);
		font-size: 12px;

		&::before,
		&::after {
			content: '';
			flex: 1;
			border-bottom: 1px solid var(--border-color);
		}

		span {
			padding: 0 10px;
		}
	}

	.error-message {
		color: var(--color-danger);
		font-size: 13px;
		text-align: center;
		background-color: rgba(var(--color-danger), 0.1);
		padding: 8px;
		border-radius: $radius-sm;
	}

	.google-wrapper {
		// Ensures your Google Component fits the width
		display: flex;
		justify-content: center;
	}

	.btn-text {
		background: none;
		border: none;
		color: var(--text-secondary);
		font-size: 13px;
		cursor: pointer;
		align-self: center;
		transition: color 0.2s;

		&:hover {
			color: var(--text-primary);
		}
	}
</style>
