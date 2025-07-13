import React, { useState } from "react";
import { backend } from "declarations/backend";
import "./app.css";

function App() {
  const [step, setStep] = useState("login");
  const [name, setName] = useState("");
  const [profile, setProfile] = useState(null);
  const [matchId, setMatchId] = useState(null);
  const [questions, setQuestions] = useState([]);
  const [answers, setAnswers] = useState([]);
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  // Login handler
  const handleLogin = async (e) => {
    e.preventDefault();
    setLoading(true);
    await backend.login(name);
    const prof = await backend.getProfile();
    setProfile(prof);
    setStep("profile");
    setLoading(false);
  };

  // Matchmaking handler
  const handleFindMatch = async () => {
    setLoading(true);
    const id = await backend.findMatch();
    if (id.length === 0) {
      alert("Menunggu lawan...");
      setLoading(false);
      return;
    }
    setMatchId(id[0]);
    const qs = await backend.getQuestions(id[0]);
    setQuestions(qs);
    setAnswers(Array(qs.length).fill(""));
    setStep("quiz");
    setLoading(false);
  };

  // Jawab kuis
  const handleAnswerChange = (idx, value) => {
    const newAnswers = [...answers];
    newAnswers[idx] = value;
    setAnswers(newAnswers);
  };

  // Submit jawaban
  const handleSubmitQuiz = async (e) => {
    e.preventDefault();
    setLoading(true);
    await backend.submitAnswer(matchId, answers.map(Number));
    // Tunggu lawan selesai
    let res = null;
    while (!res) {
      res = await backend.getResult(matchId);
      if (!res) await new Promise((r) => setTimeout(r, 1000));
    }
    setResult(res);
    const prof = await backend.getProfile();
    setProfile(prof);
    setStep("result");
    setLoading(false);
  };

  // Kembali ke profil
  const handleBackToProfile = () => {
    setMatchId(null);
    setQuestions([]);
    setAnswers([]);
    setResult(null);
    setStep("profile");
  };

  // UI rendering
  if (step === "login") {
    return (
      <main className="centered">
        <h1>Math Duel</h1>
        <form onSubmit={handleLogin}>
          <input
            type="text"
            placeholder="Masukkan nama"
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
            disabled={loading}
          />
          <button type="submit" disabled={loading || !name}>
            {loading ? "Loading..." : "Login"}
          </button>
        </form>
      </main>
    );
  }

  if (step === "profile" && profile) {
    return (
      <main className="centered">
        <h2>Profil</h2>
        <div className="card">
          <p><b>Nama:</b> {profile.name}</p>
          <p><b>Level:</b> {profile.level}</p>
          <p><b>Menang:</b> {profile.totalWins}</p>
          <p><b>Kalah:</b> {profile.totalLosses}</p>
          <p><b>Total Main:</b> {profile.totalGames}</p>
        </div>
        <button onClick={handleFindMatch} disabled={loading}>
          {loading ? "Mencari lawan..." : "Main"}
        </button>
      </main>
    );
  }

  if (step === "quiz" && questions.length > 0) {
    return (
      <main className="centered">
        <h2>Kuis Matematika</h2>
        <form onSubmit={handleSubmitQuiz}>
          {questions.map((q, idx) => (
            <div key={idx} className="question">
              <label>
                {idx + 1}. {q.text}
                <input
                  type="number"
                  value={answers[idx]}
                  onChange={(e) => handleAnswerChange(idx, e.target.value)}
                  required
                  disabled={loading}
                />
              </label>
            </div>
          ))}
          <button type="submit" disabled={loading}>
            {loading ? "Mengirim..." : "Kirim Jawaban"}
          </button>
        </form>
      </main>
    );
  }

  if (step === "result" && result) {
    return (
      <main className="centered">
        <h2>Hasil Pertandingan</h2>
        <div className="card">
          <p><b>Skor Anda:</b> {result[0]}</p>
          <p><b>Skor Lawan:</b> {result[1]}</p>
          <p>
            <b>
              {result[0] > result[1]
                ? "Anda Menang!"
                : result[0] < result[1]
                ? "Anda Kalah!"
                : "Seri!"}
            </b>
          </p>
        </div>
        <button onClick={handleBackToProfile}>Kembali ke Profil</button>
      </main>
    );
  }

  return <main className="centered">Loading...</main>;
}

export default App;