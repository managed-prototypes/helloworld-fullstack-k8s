const getConfig = async () => {
  const res = await fetch("/nocache/config.json").catch((e) => {
    throw new Error(`Failed to load config.json: ${e.message}`);
  });
  const config = await res.json().catch((_) => {
    throw new Error("Failed to decode config.json: Invalid JSON syntax");
  });
  return config;
};

(async () => {
  const config = await getConfig();
  const helloButton = document.querySelector("#hello-button") as HTMLDivElement;
  const resultText = document.querySelector("#text-result") as HTMLElement;
  const errorText = document.querySelector("#text-error") as HTMLElement;
  const helloInput = document.querySelector("#hello-input") as HTMLInputElement;

  function buttonClicked() {
    fetch(`${config.backendUrl}/hello`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(helloInput.value),
    })
      .then((response) => response.text())
      .then((x) => {
        resultText.childNodes[0].textContent = x;
        errorText.childNodes[0].textContent = " ";
      })
      .catch((e) => {
        resultText.childNodes[0].textContent = " ";
        errorText.childNodes[0].textContent = e.message;
      });
  }

  helloButton.onclick = buttonClicked;
})().catch(() => (window.location.href = "/error.html"));
