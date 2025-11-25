<h1>POINTS</h1>

<h2>LEADERBOARD</h2>


<form method="POST">
	<label for="username">Username: </label>
	<input name="username" id="username" type="text" />
	<label for="email">Email: </label>
	<input name="email" id="email" type="text" />
	<label for="password">Password: </label>
	<input name="password" id="password" type="password" required />
	<button aria-label="Submit Details">Sign Up</button>
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
</style>
