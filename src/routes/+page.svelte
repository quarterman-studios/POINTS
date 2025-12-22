<script lang="ts">
	import { enhance } from '$app/forms';
	import type { ActionData, PageData, SubmitFunction } from './$types';
	import GoogleButton from '$lib/components/GoogleButton.svelte';

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

	$inspect({ form });
</script>

<h1>POINTS</h1>

<h2>LEADERBOARD</h2>

<form method="POST" action="?/magic-link-signin" use:enhance={handleSubmit}>
	<p>{'Sign in via magic link with your email below'}</p>
	<label for="username">Username: </label>
	<input name="username" id="username" type="text" />
	<label for="email">Email: </label>
	<input name="email" id="email" type="text" />
	<button aria-label="Submit Details">{loading ? 'Loading...' : 'Send Magic Link'}</button>
	<p>{form?.message || form?.errors?.email}</p>
	<div class="google-div">
		<GoogleButton loading={googleLoading} onClick={handleGoogleSignIn} />
	</div>
</form>

<style>
	h1 {
		font-size: 3rem;
		text-align: center;
		margin-top: 2rem;
	}

	h2 {
		font-size: 2rem;
		text-align: center;
		margin-top: 1rem;
		margin-bottom: 2rem;
	}

	form {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 1rem;
	}

	label {
		margin-right: 0.5rem;
	}

	input {
		padding: 0.5rem;
		font-size: 1rem;
	}

	button {
		padding: 0.75rem 1.5rem;
		font-size: 1rem;
		cursor: pointer;
	}

	.google-div {
		margin-top: 1rem;
		display: flex;
		justify-content: center;
		width: 25%;
	}
</style>
