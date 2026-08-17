"use strict";

const form = document.getElementById("search-form");
const input = document.getElementById("search-input");
const result = document.getElementById("result");
const emptyState = document.getElementById("empty-state");
const submitButton = document.getElementById("submit-button");
const buttonText = submitButton.querySelector(".button-text");
const clearButton = document.getElementById("clear-button");
const resultStatus = document.getElementById("result-status");
const suggestionButtons = document.querySelectorAll(".suggestion");

function setStatus(message, type = "neutral") {
    resultStatus.textContent = message;
    resultStatus.className = `result-status result-status-${type}`;
}

function showResult(content) {
    emptyState.hidden = true;
    result.hidden = false;
    result.textContent = content;
}

function showEmptyState() {
    emptyState.hidden = false;
    result.hidden = true;
    result.textContent = "";
}

function updateClearButton() {
    clearButton.classList.toggle("visible", input.value.length > 0);
}

function setLoading(isLoading) {
    submitButton.disabled = isLoading;
    buttonText.textContent = isLoading ? "Recherche..." : "Rechercher";
}

input.addEventListener("input", updateClearButton);

clearButton.addEventListener("click", () => {
    input.value = "";
    input.focus();
    updateClearButton();
});

suggestionButtons.forEach((button) => {
    button.addEventListener("click", () => {
        input.value = button.dataset.query;
        updateClearButton();
        input.focus();
    });
});

form.addEventListener("submit", async (event) => {
    event.preventDefault();

    const query = input.value.trim();

    if (!query) {
        showResult("Veuillez saisir une recherche.");
        setStatus("Champ requis", "error");
        input.focus();
        return;
    }

    setLoading(true);
    setStatus("Recherche en cours", "loading");
    showResult("Connexion à l’API...");

    try {
        const response = await fetch("/search", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Accept": "application/json"
            },
            body: JSON.stringify({ query })
        });

        let data;

        try {
            data = await response.json();
        } catch {
            throw new Error("La réponse du serveur n’est pas un JSON valide.");
        }

        if (!response.ok) {
            throw new Error(
                data.message || "Une erreur est survenue pendant la recherche."
            );
        }

        showResult(JSON.stringify(data, null, 2));
        setStatus("Réponse reçue", "success");
    } catch (error) {
        showResult(`Erreur : ${error.message}`);
        setStatus("Échec de la recherche", "error");
    } finally {
        setLoading(false);
    }
});