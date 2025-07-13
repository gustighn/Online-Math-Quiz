import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

actor {
  type PlayerProfile = {
    principal : Principal;
    name : Text;
    level : Nat;
    totalGames : Nat;
    totalWins : Nat;
    totalLosses : Nat
  };

  type Question = {
    text : Text;
    answer : Int
  };

  type Match = {
    id : Nat;
    player1 : Principal;
    player2 : Principal;
    questions : [Question];
    answers : [(Principal, [Bool])];
    finished : Bool
  };

  var profiles = Buffer.Buffer<PlayerProfile>(0);
  var waitingPlayer : ?Principal = null;
  var matches = Buffer.Buffer<Match>(0);
  var matchId : Nat = 0;

  // Cari profil player dan index
  func findProfile(p : Principal) : ?(Nat, PlayerProfile) {
    for (i in Iter.range(0, profiles.size() - 1)) {
      let prof = profiles.get(i);
      if (prof.principal == p) return ?(i, prof)
    };
    return null
  };

  // Login
  public shared ({caller}) func login(name : Text) : async () {
    switch (findProfile(caller)) {
      case null {
        let profile : PlayerProfile = {
          principal = caller;
          name = name;
          level = 1;
          totalGames = 0;
          totalWins = 0;
          totalLosses = 0
        };
        profiles.add(profile)
      };
      case _ {}
    }
  };

  // Matchmaking
  public shared ({caller}) func findMatch() : async ?Nat {
    switch (waitingPlayer) {
      case null {
        waitingPlayer := ?caller;
        return null
      };
      case (?other) {
        if (other == caller) return null;
        let qs = generateQuestions(10);
        let m : Match = {
          id = matchId;
          player1 = other;
          player2 = caller;
          questions = qs;
          answers = [];
          finished = false
        };
        matches.add(m);
        matchId += 1;
        waitingPlayer := null;
        return ?(matchId - 1)
      }
    }
  };

  // Soal Matematika
  func generateQuestions(n : Nat) : [Question] {
    Array.tabulate<Question>(
      n,
      func(i) {
        let a = i + 1;
        let b = (i + 3) % 10;
        {
          text = "Berapakah " # Nat.toText(a) # " + " # Nat.toText(b) # "?";
          answer = a + b
        }
      }
    )
  };

  // Kirim jawaban
  public shared ({caller}) func submitAnswer(id : Nat, answers : [Int]) : async () {
  if (id >= matches.size()) return;
  let m = matches.get(id);
  let corrects = Array.tabulate<Bool>(
    answers.size(),
    func(i) {
      m.questions[i].answer == answers[i]
    }
  );

  // Buat array baru dengan tuple (caller, corrects)
  let newAnswers = Array.append<(Principal, [Bool])>(m.answers, [(caller, corrects)]);

  let updatedMatch : Match = {
    id = m.id;
    player1 = m.player1;
    player2 = m.player2;
    questions = m.questions;
    answers = newAnswers;
    finished = Array.size(newAnswers) == 2
  };

  if (updatedMatch.finished) {
    updateProfiles(updatedMatch)
  };

  matches.put(id, updatedMatch)
};

  // Update profil
  func updateProfiles(m : Match) {
    if (m.answers.size() < 2) return;
    let (p1, a1) = m.answers[0];
    let (p2, a2) = m.answers[1];

    let score1 = Array.foldLeft<Bool, Nat>(a1, 0, func(acc, b) {if (b) acc + 1 else acc});
    let score2 = Array.foldLeft<Bool, Nat>(a2, 0, func(acc, b) {if (b) acc + 1 else acc});

    switch (findProfile(p1), findProfile(p2)) {
      case (?(i1, prof1), ?(i2, prof2)) {
        // Buat salinan baru dari profile dengan nilai yang diupdate
        let newProf1 : PlayerProfile = {
          principal = prof1.principal;
          name = prof1.name;
          level = prof1.level;
          totalGames = prof1.totalGames + 1;
          totalWins = prof1.totalWins + (if (score1 > score2) 1 else 0);
          totalLosses = prof1.totalLosses + (if (score2 > score1) 1 else 0)
        };
        let newProf2 : PlayerProfile = {
          principal = prof2.principal;
          name = prof2.name;
          level = prof2.level;
          totalGames = prof2.totalGames + 1;
          totalWins = prof2.totalWins + (if (score2 > score1) 1 else 0);
          totalLosses = prof2.totalLosses + (if (score1 > score2) 1 else 0)
        };

        profiles.put(i1, newProf1);
        profiles.put(i2, newProf2)
      };
      case _ {}
    }
  };

  // Ambil profil
  public shared ({caller}) func getProfile() : async ?PlayerProfile {
    switch (findProfile(caller)) {
      case (?(i, p)) {?p};
      case null {null}
    }
  };

  // Ambil soal match
  public query func getQuestions(id : Nat) : async [Question] {
    if (id >= matches.size()) return [];
    let m = matches.get(id);
    m.questions
  };

  // Ambil hasil
  public query func getResult(id : Nat) : async ?(Nat, Nat) {
    if (id >= matches.size()) return null;
    let m = matches.get(id);
    if (not m.finished or m.answers.size() < 2) return null;
    let (_, a1) = m.answers[0];
    let (_, a2) = m.answers[1];
    let score1 = Array.foldLeft<Bool, Nat>(a1, 0, func(acc, b) {if (b) acc + 1 else acc});
    let score2 = Array.foldLeft<Bool, Nat>(a2, 0, func(acc, b) {if (b) acc + 1 else acc});
    ?(score1, score2)
  }
}