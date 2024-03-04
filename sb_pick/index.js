let titles = [["Help Wanted", "Reef Blower", "Tea at the Treedome", "Bubblestand", "Ripped Pants", "Jellyfishing", "Plankton!", "Naughty Nautical Neighbors", "Boating School", "Pizza Delivery", "Home Sweet Pineapple", "Mermaid Man and Barnacle Boy", "Pickles", "Hall Monitor", "Jellyfish Jam", "Sandy's Rocket", "Squeaky Boots", "Nature Pants", "Opposite Day", "Culture Shock", "F.U.N.", "MuscleBob BuffPants", "Squidward the Unfriendly Ghost", "The Chaperone", "Employee of the Month", "Scaredy Pants", "I Was a Teenage Gary", "SB-129", "Karate Choppers", "Sleepy Time", "Suds", "Valentine's Day", "The Paper", "Arrgh!", "Rock Bottom", "Texas", "Walking Small", "Fools in April", "Neptune's Spatula", "Hooky", "Mermaid Man and Barnacle Boy II"],
              ["Your Shoe's Untied", "Squid's Day Off", "Something Smells", "Bossy Boots", "Big Pink Loser", "Bubble Buddy", "Dying for Pie", "Imitation Krabs", "Wormy", "Patty Hype", "Grandma's Kisses", "Squidville", "Prehibernation Week", "Life of Crime", "Christmas Who?", "Survival of the Idiots", "Dumped", "No Free Rides", "I'm Your Biggest Fanatic", "Mermaid Man and Barnacle Boy III", "Squirrel Jokes", "Pressure", "The Smoking Peanut", "Shanghaied", "Gary Takes a Bath", "Welcome to the Chum Bucket", "Frankendoodle", "The Secret Box", "Band Geeks", "Graveyard Shift", "Krusty Love", "Procrastination", "I'm with Stupid", "Sailor Mouth", "Artist Unknown", "Jellyfish Hunter", "The Fry Cook Games", "Squid on Strike", "Sandy, SpongeBob, and the Worm"],
              ["The Algae's Always Greener", "SpongeGuard on Duty", "Club SpongeBob", "My Pretty Seahorse", "Just One Bite", "The Bully", "Nasty Patty", "Idiot Box", "Mermaid Man and Barnacle Boy IV", "Doing Time", "Snowball Effect", "One Krabs Trash", "As Seen on TV", "Can You Spare a Dime?", "No Weenies Allowed", "Squilliam Returns", "Krab Borg", "Rock-a-Bye Bivalve", "Wet Painters", "Krusty Krab Training Video", "Party Pooper Pants", "Chocolate with Nuts", "Mermaid Man and Barnacle Boy V", "New Student Starfish", "Clams", "Ugh", "The Great Snail Race", "Mid-Life Crustacean", "Born Again Krabs", "I Had an Accident", "Krabby Land", "The Camping Episode", "Missing Identity", "Plankton's Army", "The Sponge Who Could Fly", "SpongeBob Meets the Strangler", "Pranks a Lot"],
              ["", "", "", "", "Have you Seen This Snail?", "", "", "", "", "", "", "", "", "", "Krusty Towers", "", "", "", "", "", "", "", "New Leaf"]];

let s4Choices = [5,   // Have You Seen This Snail?
                 15,  // Krusty Towers
                 23]; // New Leaf

// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Math/random
function getRandomIntInclusive(min, max) {
    return Math.floor(Math.random() * (max - min + 1) + min);
}

imageBoxExists = false

document.getElementsByClassName("theButton")[0].onclick = function() {
    let season = getRandomIntInclusive(1, 4);
    var episode;
    if (season < 4) {
        episode = getRandomIntInclusive(1,
                                        (season == 1 ? 41 :
                                         season == 2 ? 39 :
                                                       37));
    }
    else
        episode = s4Choices[getRandomIntInclusive(0, 2)];

    let title = titles[season - 1][episode - 1];
    let paddedSeason = String(season).padStart(2, "0");
    let paddedEpisode = String(episode).padStart(2, "0");

    if (imageBoxExists) {
        let imageBoxes = document.getElementsByClassName("imageBox");
        for (imageBox of imageBoxes) {   
            while (imageBox.firstChild)
                imageBox.removeChild(imageBox.firstChild);
        }
    }
    else
        imageBoxExists = true;

    var imageBox = document.createElement("div");
    imageBox.className = "imageBox";
    document.body.appendChild(imageBox);

    let titleHeader = document.createElement("h3");
    titleHeader.innerHTML = `${title} - Season ${season} Episode ${episode}`;
    imageBox.appendChild(titleHeader);

    let titleCard = document.createElement("img");
    let episodeFrame = document.createElement("img");

    let titleCardFrame = '0003';
    if (season == 2 && episode == 15)      // Christmas Who?
        titleCardFrame = '0814'
    else if (season == 2 && episode == 24) // Shanghaied (You Wish)
        titleCardFrame = '0295'
    else if (season == 3 && episode == 21) // Spongebob's House Party
        titleCardFrame = '0688'
    else if (season == 3 && episode == 26) // Ugh
        titleCardFrame = '0607'
    else
        titleCardFrame = '0003'

    titleCard.src = `https://frames.everyfra.me/spongebob/S${paddedSeason}E${paddedEpisode}/${titleCardFrame}.png`;

    episodeFrame.src = `https://frames.everyfra.me/spongebob/S${paddedSeason}E${paddedEpisode}/0500.png`;
    imageBox.appendChild(titleCard);
    imageBox.appendChild(episodeFrame);  
};