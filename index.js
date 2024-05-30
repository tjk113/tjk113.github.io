// Change to dark theme if the system requests it
// https://stackoverflow.com/a/57795518
if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches)
    document.body.classList.add("darkMode");
window.matchMedia('(prefers-color-scheme: dark)').addEventListener("change", e => {
    document.body.classList.add("darkMode");
});