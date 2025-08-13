const titles = [["Help Wanted", "Reef Blower", "Tea at the Treedome", "Bubblestand", "Ripped Pants", "Jellyfishing", "Plankton!", "Naughty Nautical Neighbors", "Boating School", "Pizza Delivery", "Home Sweet Pineapple", "Mermaid Man and Barnacle Boy", "Pickles", "Hall Monitor", "Jellyfish Jam", "Sandy's Rocket", "Squeaky Boots", "Nature Pants", "Opposite Day", "Culture Shock", "F.U.N.", "MuscleBob BuffPants", "Squidward the Unfriendly Ghost", "The Chaperone", "Employee of the Month", "Scaredy Pants", "I Was a Teenage Gary", "SB-129", "Karate Choppers", "Sleepy Time", "Suds", "Valentine's Day", "The Paper", "Arrgh!", "Rock Bottom", "Texas", "Walking Small", "Fools in April", "Neptune's Spatula", "Hooky", "Mermaid Man and Barnacle Boy II"],
                ["Your Shoe's Untied", "Squid's Day Off", "Something Smells", "Bossy Boots", "Big Pink Loser", "Bubble Buddy", "Dying for Pie", "Imitation Krabs", "Wormy", "Patty Hype", "Grandma's Kisses", "Squidville", "Prehibernation Week", "Life of Crime", "Christmas Who?", "Survival of the Idiots", "Dumped", "No Free Rides", "I'm Your Biggest Fanatic", "Mermaid Man and Barnacle Boy III", "Squirrel Jokes", "Pressure", "The Smoking Peanut", "Shanghaied", "Gary Takes a Bath", "Welcome to the Chum Bucket", "Frankendoodle", "The Secret Box", "Band Geeks", "Graveyard Shift", "Krusty Love", "Procrastination", "I'm with Stupid", "Sailor Mouth", "Artist Unknown", "Jellyfish Hunter", "The Fry Cook Games", "Squid on Strike", "Sandy, SpongeBob, and the Worm"],
                ["The Algae's Always Greener", "SpongeGuard on Duty", "Club SpongeBob", "My Pretty Seahorse", "Just One Bite", "The Bully", "Nasty Patty", "Idiot Box", "Mermaid Man and Barnacle Boy IV", "Doing Time", "Snowball Effect", "One Krabs Trash", "As Seen on TV", "Can You Spare a Dime?", "No Weenies Allowed", "Squilliam Returns", "Krab Borg", "Rock-a-Bye Bivalve", "Wet Painters", "Krusty Krab Training Video", "Party Pooper Pants", "Chocolate with Nuts", "Mermaid Man and Barnacle Boy V", "New Student Starfish", "Clams", "Ugh", "The Great Snail Race", "Mid-Life Crustacean", "Born Again Krabs", "I Had an Accident", "Krabby Land", "The Camping Episode", "Missing Identity", "Plankton's Army", "The Sponge Who Could Fly", "SpongeBob Meets the Strangler", "Pranks a Lot"],
                ["", "", "", "", "Have you Seen This Snail?", "", "", "", "", "", "", "", "", "", "Krusty Towers", "", "", "", "", "", "", "", "New Leaf"]];

const s4Choices = [5,   // Have You Seen This Snail?
                   15,  // Krusty Towers
                   23]; // New Leaf
const s4Weight = 0.25;

const productionNumberToEpisode = [["1a", "1b", "1c", "2a", "2b", "3a", "3b", "4a", "4b", "5a", "5b", "6a", "6b", "7a", "7b", "8a", "8b", "9a", "9b", "10a", "10b", "11a", "11b", "12a", "12b", "13a", "13b", "14a", "14b", "15a", "15b", "16a", "16b", "17a", "17b", "18a", "18b", "19a", "19b", "20a", "20b"],
                                   ["1a", "1b", "2a", "2b", "3a", "3b", "4a", "4b", "5a", "5b", "6a", "6b", "7a", "7b", "8", "9a", "9b", "10a", "10b", "11a", "11b", "12a", "12b", "13a", "13b", "14a", "14b", "15a", "15b", "16a", "16b", "17a", "17b", "18a", "18b", "19a", "19b", "20a", "20b"],
                                   ["1a", "1b", "2a", "2b", "3a", "3b", "4a", "4b", "5a", "5b", "6a", "6b", "7a", "7b", "8a", "8b", "9a", "9b", "10a", "10b", "11", "12a", "12b", "13a", "13b", "14", "15a", "15b", "16a", "16b", "17a", "17b", "18a", "18b", "19", "20a", "20b"],
                                   ["", "", "", "", "3", "", "", "", "", "", "", "", "", "", "9a", "", "", "", "", "", "", "", "13a"]];

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/random
function getRandomIntInclusive(min, max) {
    return Math.floor(Math.random() * (max - min + 1) + min);
}

function getRandomEpisode() {
    let season = getRandomIntInclusive(1, 4);
    var episode;
    /* Only a 25% chance a season 4 episode is picked even if
    it is the randomly selected season. */
    if (season < 4 && getRandomIntInclusive(1, 4) > 1) {
        episode = getRandomIntInclusive(1,
                                        (season == 1 ? 41 :
                                         season == 2 ? 39 :
                                                       37));
    }
    else
        episode = s4Choices[getRandomIntInclusive(0, 2)];
    
    return {
        title: titles[season - 1][episode - 1],
        season: season,
        episodeNumber: productionNumberToEpisode[season - 1][episode - 1],
        productionNumber: episode
    };
}

let imageBoxExists = false;
let body = document.getElementsByTagName("body")[0];
let theButton = document.getElementsByClassName("theButton");

/* Other modules that import `getRandomEpisode`
have to resolve to the global scope, so we
have to make sure `theButton` is defined
before we use it. */
if (theButton.length != 0) {
    theButton = theButton[0];
    theButton.onclick = async function() {
        theButton.classList.add("animateTheButton");

        if (imageBoxExists) {
            body.classList.remove("animateBodyUp");
            body.classList.add("animateBodyDown");
        }

        let episode = getRandomEpisode();

        if (imageBoxExists) {
            let imageBox = document.getElementsByClassName("imageBox")[0];
            let titleHeader = document.getElementsByTagName("h3")[0];
            imageBox.classList.add("animateImageBoxOut");
            await new Promise((r) => setTimeout(r, 500));
            titleHeader.remove();
            imageBox.remove();
        }
        else
            imageBoxExists = true;

        let titleHeader = document.createElement("h3");
        titleHeader.innerHTML = `${episode.title} - Season ${episode.season} Episode ${episode.episodeNumber}`;
        titleHeader.style.display = "none";
        document.body.appendChild(titleHeader);

        var imageBox = document.createElement("div");
        imageBox.className = "imageBox";
        document.body.appendChild(imageBox);

        let titleCard = document.createElement("img");
        titleCard.style.display = "none";
        let episodeFrame = document.createElement("img");
        episodeFrame.style.display = "none";

        let titleCardFrame = "3";
        if (episode.season == 2 && episode.episodeNumber == 15)      // Christmas Who?
            titleCardFrame = "814";
        else if (episode.season == 2 && episode.episodeNumber == 24) // Shanghaied (You Wish)
            titleCardFrame = "295";
        else if (episode.season == 3 && episode.episodeNumber == 21) // Spongebob's House Party
            titleCardFrame = "688";
        else if (episode.season == 3 && episode.episodeNumber == 26) // Ugh
            titleCardFrame = "607";
        else if (episode.season == 4 && episode.episodeNumber == 4)  // Have You Seen This Snail?
            titleCardFrame = "178";

        titleCard.src = `https://backend.everyfra.me/spongebob/s${episode.season}e${episode.productionNumber}/${titleCardFrame}.png`;
        episodeFrame.src = `https://backend.everyfra.me/spongebob/s${episode.season}e${episode.productionNumber}/500.png`;

        imageBox.appendChild(titleCard);
        imageBox.appendChild(episodeFrame);
        
        // Give the images 2.5s to load (the server is slow)
        await new Promise((r) => setTimeout(r, 2500));

        body.classList.add("animateBodyUp");

        titleHeader.style.display = "block";
        titleCard.style.display = "block";
        episodeFrame.style.display = "block";

        imageBox.classList.add("animateImageBoxIn");
        theButton.classList.remove("animateTheButton");
        body.classList.remove("animateBodyDown");
    };
}