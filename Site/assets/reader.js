window.CifraSantaReader = (() => {
    let timer = null;
    let metronomeTimer = null;
    let audioContext = null;
    let beat = 0;
    const click = () => {
        audioContext ??= new (window.AudioContext || window.webkitAudioContext)();
        if (audioContext.state === "suspended") audioContext.resume();
        const oscillator = audioContext.createOscillator();
        const gain = audioContext.createGain();
        const now = audioContext.currentTime;
        oscillator.frequency.value = beat++ % 4 === 0 ? 980 : 720;
        gain.gain.setValueAtTime(0.001, now);
        gain.gain.exponentialRampToValueAtTime(0.16, now + 0.003);
        gain.gain.exponentialRampToValueAtTime(0.001, now + 0.055);
        oscillator.connect(gain).connect(audioContext.destination);
        oscillator.start(now);
        oscillator.stop(now + 0.06);
    };
    return {
        start() {
            if (timer !== null) return;
            timer = window.setInterval(() => {
                window.scrollBy(0, 1);
                if (window.innerHeight + window.scrollY >= document.documentElement.scrollHeight - 2) this.stop();
            }, 35);
        },
        stop() {
            if (timer !== null) window.clearInterval(timer);
            timer = null;
        },
        startMetronome(bpm) {
            this.stopMetronome();
            click();
            metronomeTimer = window.setInterval(click, 60000 / bpm);
        },
        stopMetronome() {
            if (metronomeTimer !== null) window.clearInterval(metronomeTimer);
            metronomeTimer = null;
        },
        print() {
            window.print();
        },
        download(filename, content) {
            const url = URL.createObjectURL(new Blob([content], { type: "text/plain;charset=utf-8" }));
            const anchor = document.createElement("a");
            anchor.href = url;
            anchor.download = filename;
            document.body.appendChild(anchor);
            anchor.click();
            anchor.remove();
            window.setTimeout(() => URL.revokeObjectURL(url), 1000);
        }
    };
})();
