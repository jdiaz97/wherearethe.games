// This is manages the list of games, filters and more.    

let countryNameFlag = "https://flagicons.lipis.dev/flags/4x3/" + country_code + ".svg";
document.getElementById('countryName').textContent = country_data;
document.getElementById('countryFlag').src = countryNameFlag;
document.getElementById('countryFlag').alt = country_data + " flag";

// Global variables
let allGames = [];
let bitVector_years = [];
let bitVector_genres = []
let bitVector_platforms = []
let uniqueCountries = new Set([country_data]);

// ascending and descending
document.getElementById('sort-toggle').addEventListener('click', function () {
    const sortButton = document.getElementById('sort-toggle');
    const currentOrder = sortButton.getAttribute('data-order');
    const newOrder = currentOrder === 'ascending' ? 'descending' : 'ascending';
    sortButton.setAttribute('data-order', newOrder);
    document.getElementById('sort-text').innerText = newOrder.charAt(0).toUpperCase() + newOrder.slice(1);
});


function updateGameCountDisplay(bitVector_games) {
    const sum = bitVector_games.reduce((acc, val) => acc + val, 0);
    const total = bitVector_games.length;
    document.getElementById('gameCountDisplay').textContent =
        `Showing ${sum} out of ${total} games`;
}

// Function to parse CSV text into an array of objects
function parseCSV(csvText) {
    const rows = csvText.split('\n');
    const headers = rows[0].split(';');

    return rows.slice(1, -1).map(row => {
        const values = row.split(';');

        return headers.reduce((obj, header, index) => {
            let value = values[index]?.trim() || '';

            if (header.trim() === 'Release_Date') {
                value = new Date(value);
            }

            obj[header.trim()] = value;
            return obj;
        }, {});
    });
}

async function fetchCSVData(url) {
    try {
        const response = await fetch(url);
        const csvText = await response.text();
        return parseCSV(csvText);
    } catch (error) {
        console.error('Error fetching CSV:', error);
        return [];
    }
}


async function fetchMultipleCSVData(urls) {
    const fetchPromises = urls.map(url => fetchCSVData(url));
    const results = await Promise.all(fetchPromises);
    return results.flat();
}

async function fetchCSVData(url) {
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error(`Failed to fetch ${url}: ${response.statusText}`);
        }
        const csvText = await response.text();
        return parseCSV(csvText); // Process CSV into usable data
    } catch (error) {
        console.error(`Error fetching or processing ${url}:`, error);
        return []; // Return an empty array if there's an error
    }
}

// function createCountryFilterButtons() {
//     const filterContainer = document.getElementById('filterButtons-country');
//     filterContainer.innerHTML = '<select id="countryFilter" onchange="filter_by_country(this.value)">' +
//         '<option value="all">All Countries</option>';

//     // Assuming uniqueCountries (global variable) is already defined and populated
//     uniqueCountries.forEach(country => {
//         filterContainer.querySelector('select').innerHTML += `<option value="${country}">${country}</option>`;
//     });

//     // Add change event listener to highlight the selected option
//     filterContainer.querySelector('select').addEventListener('change', function (e) {
//         this.classList.add('active');
//     });
// }

function createGenreFilterButtons() {
    const filterContainer = document.getElementById('filterButtons-genre');

    // Genre filter
    filterContainer.innerHTML += '<select id="genreFilter" onchange="filter_by_genre(this.value)">' +
        '<option value="all">All Genres</option>';

    // Extract all unique genres
    const uniqueGenres = [...new Set(allGames.flatMap(game =>
        game.Genre.split(',').map(genre => genre.trim())
    ))];
    uniqueGenres.sort();

    uniqueGenres.forEach(genre => {
        const displayGenre = genre || "Unspecified";
        filterContainer.querySelector('#genreFilter').innerHTML += `<option value="${genre}">${displayGenre}</option>`;
    });

    // Add change event listeners to highlight the selected options
    filterContainer.querySelectorAll('select').forEach(select => {
        select.addEventListener('change', function (e) {
            this.classList.add('active');
        });
    });
}

function filter_by_genre(genre) {
    if (genre === 'all') {
        bitVector_genres.fill(1);
    } else {
        bitVector_genres = allGames.map(game =>
            game.Genre.split(',').map(g => g.trim()).includes(genre) ? 1 : 0
        );
    }
    refresh();
    // Highlight the appropriate option
    const genreFilter = document.getElementById('genreFilter');
    genreFilter.value = genre;
    genreFilter.classList.add('active');
}

function createYearFilterButtons() {
    const filterContainer = document.getElementById('filterButtons-year');
    filterContainer.innerHTML = '<select id="yearFilter" onchange="filter_by_year(this.value)">' +
        '<option value="all">All Years</option>';
    
    // Extract years and handle TBA entries
    const years = allGames.map(game => {
        const year = game.Release_Date.getFullYear();
        return {
            value: isNaN(year) ? "To be announced" : year,
            isNumber: !isNaN(year)
        };
    });
    
    // Create a Set of unique entries and convert to array
    const uniqueYears = [...new Set(years.map(y => y.value))];
    
    // Custom sort function - modified to put "To be announced" first
    const sortedYears = uniqueYears.sort((a, b) => {
        // If one is "To be announced", put it at the beginning
        if (a === "To be announced") return -1;
        if (b === "To be announced") return 1;
        // If both are numbers, sort descending
        if (typeof a === 'number' && typeof b === 'number') {
            return b - a;
        }
        // Fallback comparison
        return 0;
    });
    
    // Create options
    const select = filterContainer.querySelector('select');
    sortedYears.forEach(year => {
        select.innerHTML += `<option value="${year}">${year}</option>`;
    });
    
    // Add change event listener
    select.addEventListener('change', function(e) {
        this.classList.add('active');
    });
}

function createPlatformFilterButtons() {
    const filterContainer = document.getElementById('filterButtons-platforms');

    // Platform filter
    filterContainer.innerHTML += '<select id="platformFilter" onchange="filter_by_platform(this.value)">' +
        '<option value="all">All Platforms</option>';

    // Extract all unique platforms
    const uniquePlatforms = [...new Set(allGames.flatMap(game =>
        game.Platform.split(',').map(platform => platform.trim())
    ))];
    uniquePlatforms.sort();

    uniquePlatforms.forEach(platform => {
        const displayPlatform = platform || "Unspecified";
        filterContainer.querySelector('#platformFilter').innerHTML += `<option value="${platform}">${displayPlatform}</option>`;
    });

    // Add change event listeners to highlight the selected options
    filterContainer.querySelectorAll('select').forEach(select => {
        select.addEventListener('change', function (e) {
            this.classList.add('active');
        });
    });
}

function filter_by_platform(platform) {
    if (platform === 'all') {
        bitVector_platforms.fill(1);
    } else {
        bitVector_platforms = allGames.map(game =>
            game.Platform.split(',').map(p => p.trim()).includes(platform) ? 1 : 0
        );
    }
    refresh();
    // Highlight the appropriate option
    const platformFilter = document.getElementById('platformFilter');
    platformFilter.value = platform;
    platformFilter.classList.add('active');
}

function createGameCard(game) {
    return `<div class="game-card">
    <div class="game-header" title="${game.Name}">${game.Name}</div>
    <img src="${game.Thumbnail}" alt="${game.Name} Thumbnail" class="game-thumbnail" loading="lazy">
    <div class="game-info">
        <div class="info-item">
            <span class="info-label">Genre</span>
            <span class="genre" title="${game.Genre}">${game.Genre}</span>
        </div>
        <div class="info-container">
            <div class="info-itemdevpub">
                <span class="info-labeldevpub">Developer</span>
                ${game.Developer_Names}
            </div>
            <div class="info-itemdevpub">
                <span class="info-labeldevpub" title="${game.Publisher_Names}">Publisher</span>
                ${game.Publisher_Names}
            </div>
        </div>
        <div class="info-item">
            <span class="info-label">Description</span>
            <div class="description">
                <span class="game-description">${game.Description}</span>
                <span class="read-more" id="readMoreBtn">Read More</span>
            </div>
            <div id="message" style="display: none; color: red;">Not available yet</div>
        </div>  
        
        <div class="info-container2">
            <div class="info-platform">
                <span class="info-labelplatform" title="${game.Platform}">Platforms</span>
                ${game.Platform}
            </div>
            <div class="info-item">
                <span class="info-labelplatform">Where to Buy</span>
                <div class="platform-icons">
                    <a href="${game.Steam_Link}" class="platform-link steam-link" target="_blank">
                        <img src="../assets/steam.webp" alt="Steam" class="platform-logo">
                    </a>
                    ${game.Epic_Link && game.Epic_Link !== "Unknown" ? `
                    <a href="${game.Epic_Link}" class="platform-link epic-link" target="_blank">
                        <img src="../assets/epic.webp" alt="Epic Games" class="platform-logo">
                    </a>` : ''}
                    ${game.PlayStation_Link && game.PlayStation_Link !== "Unknown" ? `
                    <a href="${game.Playstation_Link}" class="platform-link playstation-link" target="_blank">
                        <img src="../assets/playstation.webp" alt="PlayStation" class="platform-logo">
                    </a>` : ''}
                    ${game.Xbox_Link && game.Xbox_Link !== "Unknown" ? `
                    <a href="${game.Xbox_Link}" class="platform-link xbox-link" target="_blank">
                        <img src="../assets/xbox.webp" alt="Xbox" class="platform-logo">
                    </a>` : ''}
                    ${game.GOG_Link && game.GOG_Link !== "Unknown" ? `
                        <a href="${game.GOG_Link}" class="platform-link gog-link" target="_blank">
                            <img src="../assets/gog.webp" alt="GOG" class="platform-logo">
                        </a>` : ''}
                    ${game.Switch_Link && game.Switch_Link !== "Unknown" ? `
                    <a href="${game.Switch_Link}" class="platform-link nintendo-link" target="_blank">
                        <img src="../assets/nintendo.webp" alt="Nintendo" class="platform-logo">
                    </a>` : ''}
                </div>
            </div>
        </div>
        
        <div class="info-item">
            <span class="info-label">Release Date</span>
            ${game.Release_Date instanceof Date && !isNaN(game.Release_Date) ? game.Release_Date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }) : "To be announced"}
        </div>
    </div>
</div>`;
}

// Global event listener
document.getElementById('gameContainer').addEventListener('click', handleCardClick);

function handleCardClick(e) {
    if (e.target.classList.contains('read-more')) {
        const card = e.target.closest('.game-card');
        if (card) {
            const isExpanded = card.classList.toggle('expanded');
            e.target.textContent = isExpanded ? 'Not available yet, sorry!' : 'Read More';
        }
    }
}

function renderGames(gamesData) {
    const container = document.getElementById('gameContainer');
    container.innerHTML = gamesData.map(game => createGameCard(game)).join('');
}

function bitvectorAND(...vectors) {
    return vectors[0].map((_, index) =>
        vectors.reduce((acc, vector) => acc & vector[index], ~0)
    );
}

function filter_and_render(bitVector) {
    const filteredGames = allGames.filter((_, index) => bitVector[index] == 1);
    renderGames(filteredGames);
}

function vector_state() {
    return bitvectorAND(bitVector_years, bitVector_genres, bitVector_platforms)
}


function refresh() {
    filter_and_render(vector_state());
    updateGameCountDisplay(vector_state());
}

function filter_by_year(year) {
    if (year == 'all') {
        bitVector_years.fill(1)
    } else if (year == 'To be announced') {
        bitVector_years = allGames.map(game => {
            return isNaN(game.Release_Date.getTime()) ? 1 : 0;
        });
    } else {
        bitVector_years = allGames.map(game => {
            const releaseYear = game.Release_Date.getFullYear();
            return releaseYear == year ? 1 : 0;
        });
    }
    refresh();
    // Highlight the appropriate button
    const filterContainer = document.getElementById('filterButtons-year');
    filterContainer.querySelectorAll('button').forEach(btn => {
        btn.classList.remove('active');
        if ((year === 'all' && btn.textContent === 'All Years') ||
            btn.textContent === year) {
            btn.classList.add('active');
        }
    });
}

async function main() {
    // Dynamically generate URLs for each country
    const baseUrl = 'https://raw.githubusercontent.com/jdiaz97/wherearethe.games/main/export/';
    const csvUrls = Array.from(uniqueCountries).map(country => `${baseUrl}${country}.csv`);

    try {
        allGames = await fetchMultipleCSVData(csvUrls);

        bitVector_years = new Array(allGames.length).fill(1);  // Initialize with size 10 and all 0s
        bitVector_genres = new Array(allGames.length).fill(1);  // Initialize with size 10 and all 0s
        bitVector_platforms = new Array(allGames.length).fill(1);  // Initialize with size 10 and all 0s
        filter_and_render(bitVector_years);
        updateGameCountDisplay(bitVector_years);
    } catch (error) {
        console.error('Error fetching or processing data:', error);
    }

    // createCountryFilterButtons();
    createGenreFilterButtons();
    createYearFilterButtons();
    createPlatformFilterButtons();
}

main();

// Assume allGames is an array of objects with Name and Release_Date properties

const orderBySelect = document.getElementById('order-by');
const sortToggleButton = document.getElementById('sort-toggle');
let currentSortOrder = 'ascending';

function reorder_by_indices(indices) {
    // Use the sorted indices to reorder allGames and bitvectors
    allGames = indices.map(i => allGames[i]);
    bitVector_years = indices.map(i => bitVector_years[i]);
    bitVector_genres = indices.map(i => bitVector_genres[i]);
    bitVector_platforms = indices.map(i => bitVector_platforms[i]);
}

function sortGames() {
    const sortOrder = currentSortOrder; // Ascending vs Descending

    let indices = Array.from(Array(allGames.length).keys());

    // Sort the indices based on the game data
    indices.sort((a, b) => {
        let comparison = allGames[a].Name.localeCompare(allGames[b].Name);
        return sortOrder === 'ascending' ? comparison : -comparison;
    });

    reorder_by_indices(indices)
    refresh();
}

orderBySelect.addEventListener('change', sortGames);

sortToggleButton.addEventListener('click', () => {
    currentSortOrder = currentSortOrder === 'ascending' ? 'descending' : 'ascending';
    sortToggleButton.setAttribute('data-order', currentSortOrder);
    document.getElementById('sort-text').textContent = currentSortOrder.charAt(0).toUpperCase() + currentSortOrder.slice(1);
    document.getElementById('arrow').textContent = currentSortOrder === 'ascending' ? '↑' : '↓';
    sortGames();
});

const navToggle = document.querySelector('.nav-toggle');
const navLinks = document.querySelector('.nav-links');

navToggle.addEventListener('click', () => {
    navLinks.classList.toggle('active');
});
