let resources;

function fetchResources() {
	return fetch('resources').then(resp => resp.json()).then(resp => {
		resources = resp;
		resources.sort((a, b) => a.name > b.name);
	});
}

function updateResources() {
	let resourcesDiv = document.getElementById('resources');
	let showRegularResources = document.getElementById('regular-resources').getAttribute('enabled') == 'yes';
	let showManagedResources = document.getElementById('managed-resources').getAttribute('enabled') == 'yes';
	let showDefaultResources = document.getElementById('default-resources').getAttribute('enabled') == 'yes';

	resourcesDiv.innerHTML = '';

	let numRegular = 0;
	let numManaged = 0;
	let numDefault = 0;

	resources.forEach(resource => {
		if (!(resource.isDefaultResource || resource.isManagedResource)) {
			++numRegular;
		}
		if (resource.isManagedResource) {
			++numManaged;
		}
		if (resource.isDefaultResource) {
			++numDefault;
		}

		if (showRegularResources && (resource.isDefaultResource || resource.isManagedResource)) {
			return;
		} else if (showManagedResources && !resource.isManagedResource) {
			return;
		} else if (showDefaultResources && !resource.isDefaultResource) {
			return;
		}

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

			if (Array.isArray(author)) {
				author = author.join(', ');
			}

			let titleDiv = document.createElement('div');
			titleDiv.className = 'resource-title';

			if (link) {
				titleDiv.innerHTML = `<a href="${link}" target="_blank">${name} ${version} by ${author}</a>`
			} else {
				titleDiv.innerHTML = `${name} ${version} by ${author}`;
			}

			infoDiv.appendChild(titleDiv);
		}

		resourceDiv.appendChild(infoDiv);

		let progressDiv = document.createElement('div');
		progressDiv.className = 'resource-progress';
		resourceDiv.appendChild(progressDiv);

		let badgesDiv = document.createElement('div');
		badgesDiv.className = 'resource-badges';
		if (resource.isDefaultResource) {
			badgesDiv.innerHTML += '<i class="fas fa-box-open" title="This is a default resource"></i>';
		}
		if (resource.isManagedResource) {
			badgesDiv.innerHTML += '<i class="fas fa-cogs" title="This is a managed resource"></i>';
		}
		resourceDiv.appendChild(badgesDiv);

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

	document.getElementById('total-resources').innerHTML = numRegular + numManaged + numDefault;
	document.getElementById('num-regular-resources').innerHTML = numRegular;
	document.getElementById('num-managed-resources').innerHTML = numManaged;
	document.getElementById('num-default-resources').innerHTML = numDefault;
}

function refreshResources() {
	fetchResources().then(() => updateResources());
}

window.addEventListener('load', function(e) {
	document.querySelectorAll('.filter-button').forEach(e => e.addEventListener('click', function(e) {
		document.querySelectorAll('.filter-button').forEach(button => {
			if (button == this) {
				button.setAttribute('enabled', 'yes');
				button.className = 'filter-button btn btn-success';
			} else {
				button.setAttribute('enabled', 'no');
				button.className = 'filter-button btn btn-dark';
			}
		});

		updateResources();
	}));

	document.getElementById('refresh').addEventListener('click', function(e) {
		fetch('refresh').then(() => refreshResources());
	});

	refreshResources();
});
