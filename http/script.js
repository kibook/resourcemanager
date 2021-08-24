function refreshResources() {
	fetch('resources').then(resp => resp.json()).then(resources => {
		let resourcesDiv = document.getElementById('resources');

		resourcesDiv.innerHTML = '';

		resources.sort((a, b) => a.name > b.name);

		resources.forEach(resource => {
			let resourceDiv = document.createElement('div');

			if (resource.state == 'started') {
				resourceDiv.className = 'card mb-3 resource started';
			} else {
				resourceDiv.className = 'card mb-3 resource stopped';
			}

			let infoDiv = document.createElement('div');
			infoDiv.className = 'resource-info';

			let nameDiv = document.createElement('div');
			nameDiv.className = 'resource-name';
			nameDiv.innerHTML = resource.name;
			nameDiv.title = resource.path;
			infoDiv.appendChild(nameDiv);

			if (resource.metadata.author) {
				let name = resource.metadata.name || '';
				let version = resource.metadata.version || '';
				let author = resource.metadata.author || '';
				let link = resource.metadata.url || resource.metadata.repository;

				let titleDiv = document.createElement('div');
				titleDiv.className = 'resource-title';

				if (link) {
					titleDiv.innerHTML = `<a href="${link}">${name} ${version} by ${author}</a>`
				} else {
					titleDiv.innerHTML = `${name} ${version} by ${author}`;
				}

				infoDiv.appendChild(titleDiv);
			}

			resourceDiv.appendChild(infoDiv);

			let progressDiv = document.createElement('div');
			progressDiv.className = 'resource-progress';
			resourceDiv.appendChild(progressDiv);

			let buttonsDiv = document.createElement('div');
			buttonsDiv.className = 'resource-buttons';

			let startButton = document.createElement('button');
			startButton.innerHTML = 'Start';
			buttonsDiv.appendChild(startButton);

			let restartButton = document.createElement('button');
			restartButton.innerHTML = 'Restart';
			buttonsDiv.appendChild(restartButton);

			let stopButton = document.createElement('button');
			stopButton.innerHTML = 'Stop'
			buttonsDiv.appendChild(stopButton);

			if (resource.state == 'started') {
				restartButton.className = 'btn btn-warning';
				restartButton.addEventListener('click', e => {
					progressDiv.innerHTML = 'Restarting...';
					restartButton.disabled = true;
					fetch(`restart/${resource.name}`).then(resp => {
						progressDiv.innerHTML = '';
						restartButton.disabled = false;
						refreshResources();
					});
				});

				stopButton.className = 'btn btn-danger';
				stopButton.addEventListener('click', e => {
					progressDiv.innerHTML = 'Stopping...';
					stopButton.disabled = true;
					fetch(`stop/${resource.name}`).then(resp => {
						progressDiv.innerHTML = '';
						stopButton.disabled = false;
						refreshResources();
					});
				});

				startButton.className = 'btn btn-secondary';
				startButton.disabled = true;
			} else {
				startButton.className = 'btn btn-success';
				startButton.addEventListener('click', e => {
					progressDiv.innerHTML = 'Starting...';
					startButton.disabled = true;
					fetch(`start/${resource.name}`).then(resp => {
						progressDiv.innerHTML = '';
						startButton.disabled = false;
						refreshResources();
					});
				});

				restartButton.className = 'btn btn-secondary';
				restartButton.disabled = true;
				stopButton.className = 'btn btn-secondary';
				stopButton.disabled = true;
			}

			resourceDiv.appendChild(buttonsDiv);

			resourcesDiv.appendChild(resourceDiv);
		});
	});
}

window.addEventListener('load', function(e) {
	document.getElementById('refresh').addEventListener('click', function(e) {
		fetch('refresh').then(resp => refreshResources());
	});

	refreshResources();
});
