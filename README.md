<h1>📸 Galleria</h1>

<p>
  <a href="https://flutter.dev/">
    <img src="https://img.shields.io/badge/Flutter-v3.0%2B-blue?logo=flutter" alt="Flutter">
  </a>
  <a href="https://supabase.com/">
    <img src="https://img.shields.io/badge/Supabase-Backend-success?logo=supabase" alt="Supabase">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
  </a>
</p>

<p>
  <strong>Galleria</strong> è una moderna applicazione Flutter che ti consente di gestire, visualizzare, caricare e organizzare la tua galleria fotografica personale in cloud in modo semplice, rapido e sicuro.
</p>

<hr>

<h2>✨ Funzionalità principali</h2>
<ul>
  <li><strong>Visualizzazione foto in griglia</strong>: Sfoglia le tue immagini in una galleria ordinata e accattivante.</li>
  <li><strong>Caricamento immagini</strong>: Carica nuove foto dalla galleria del dispositivo o scatta direttamente tramite fotocamera.</li>
  <li><strong>Eliminazione intelligente</strong>: Elimina singole foto con un tap prolungato o cancella tutta la galleria con un solo click (con doppia conferma di sicurezza).</li>
  <li><strong>Visualizzazione dettagliata &amp; swipe</strong>: Tocca una foto per vederla in dettaglio, oppure usa la modalità PageView per scorrere orizzontalmente tra le immagini.</li>
  <li><strong>Indicatore pagine e UX avanzata</strong>: Navigazione fluida con indicatori grafici e caricamento ottimizzato delle immagini.</li>
  <li><strong>Logout sicuro &amp; gestione sessione</strong></li>
  <li><strong>Modalità istruzioni integrate</strong>: Accesso rapido alle istruzioni per l’uso tramite dialog dedicato.</li>
</ul>

<hr>


<h2>⚙️ Tecnologie e dipendenze</h2>
<ul>
  <li><a href="https://flutter.dev/">Flutter</a> (cross-platform UI)</li>
  <li><a href="https://supabase.com/">Supabase</a> (backend, autenticazione e storage)</li>
  <li><a href="https://pub.dev/packages/image_picker">image_picker</a> (selezione immagini dal device)</li>
  <li><a href="https://pub.dev/packages/cached_network_image">cached_network_image</a> (caching immagini da network)</li>
  <li><a href="https://pub.dev/packages/smooth_page_indicator">smooth_page_indicator</a> (indicatori pagine)</li>
</ul>

<hr>

<h2>📂 Struttura del progetto</h2>
<pre>
lib/
├── main.dart                   # Entry point
├── pagina_utente.dart          # Galleria personale (vista principale)
├── utente_alternativo.dart     # Visualizzazione alternativa (PageView)
├── dettagli_foto.dart          # Dettaglio singola foto
├── photo.dart                  # Modello dati foto
</pre>

<hr>

<h2>🚀 Come iniziare</h2>
<ol>
  <li><strong>Clona il repository</strong>
    <pre><code>git clone https://github.com/fragarray/galleria.git
cd galleria</code></pre>
  </li>
  <li><strong>Installa le dipendenze</strong>
    <pre><code>flutter pub get</code></pre>
  </li>
  <li><strong>Configura Supabase</strong><br>
    Inserisci le tue chiavi Supabase e la configurazione nel file appropriato (vedi documentazione Supabase per Flutter).
  </li>
  <li><strong>Avvia l’app</strong>
    <pre><code>flutter run</code></pre>
  </li>
</ol>

<hr>

<h2>🛡️ Sicurezza e Privacy</h2>
<ul>
  <li>Le immagini caricate sono visibili solo all’utente autenticato.</li>
  <li>Le operazioni di eliminazione richiedono conferma esplicita.</li>
  <li>Logout gestito in modo sicuro tramite Supabase.</li>
</ul>

<hr>

<h2>🤝 Contribuzione</h2>
<p>
Hai idee, bug o suggerimenti?<br>
Apri una <a href="https://github.com/fragarray/galleria/issues">issue</a> oppure una pull request!<br>
Ogni contributo è il benvenuto.
</p>

<hr>

<h2>📄 Licenza</h2>
<p>Questo progetto è distribuito sotto licenza MIT.<br>
Consulta il file <a href="LICENSE">LICENSE</a> per tutti i dettagli.</p>

<hr>
<p>
  <em>Realizzato con ❤️ da <a href="https://github.com/fragarray">fragarray</a> usando Flutter e Supabase.</em>
</p>
