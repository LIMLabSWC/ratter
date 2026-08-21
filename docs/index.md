---
title: BControl Documentation
layout: default
---

<div class="intro-section">
    <h2>About BControl</h2>
    <p><strong>BControl</strong> is a behavioral experimentation system that provides a flexible and extensible framework for running behavioral protocols. Originally developed by the Brody Lab, this system is now used and maintained by the Akrami Lab for our high-throughput behavior training facility. Designed to support a variety of experiments with user-friendly configuration and robust MATLAB-based components, BControl enables researchers to design, implement, and execute complex behavioral experiments with precise control over experimental parameters, data collection, and protocol management.</p>
    <p>For the original BControl documentation and resources, visit the <a href="https://brodylabwiki.princeton.edu/bcontrol/index.php?title=Main_Page" target="_blank">Brody Lab BControl Wiki</a>.</p>
</div>

<div class="nav-grid">
    <div class="nav-card">
        <h3>📚 User Guides</h3>
        <ul>
            <li><a href="{{ '/guides/protocol-writers-guide' | relative_url }}">Protocol Writer's Guide</a></li>
            <li><a href="{{ '/guides/solo-core-guide' | relative_url }}">Solo Core Guide</a></li>
            <li><a href="{{ '/guides/water-valve-tutorial' | relative_url }}">Water Valve Tutorial</a></li>
        </ul>
    </div>

    <div class="nav-card">
        <h3>🏗️ System Architecture</h3>
        <ul>
            <li><a href="{{ '/architecture/system-overview' | relative_url }}">System Overview</a></li>
            <li><a href="{{ '/architecture/system-architecture' | relative_url }}">System Architecture</a></li>
            <li><a href="{{ '/architecture/legacy-architecture' | relative_url }}">Legacy Architecture Notes</a></li>
            <li><a href="{{ '/archive/may-2025-modernization/README' | relative_url }}">May 2025 Modernization (archive)</a></li>
        </ul>
    </div>

    <div class="nav-card">
        <h3>🔧 Technical References</h3>
        <ul>
            <li><a href="{{ '/technical/fsm-documentation' | relative_url }}">Finite State Machine (FSM) Documentation</a></li>
            <li><a href="{{ '/technical/staircases' | relative_url }}">Staircase Algorithms</a></li>
            <li><a href="{{ '/technical/svn_update_process' | relative_url }}">SVN Update Process</a></li>
        </ul>
    </div>

    <div class="nav-card">
        <h3>🧪 Protocols</h3>
        <ul>
            <li><a href="{{ '/protocols_overview' | relative_url }}">Protocols Overview</a></li>
            <li><a href="https://github.com/LIMLabSWC/ratter/tree/main/Protocols/@ArpitCentrePokeTraining">Training Protocols</a></li>
            <li><a href="https://github.com/LIMLabSWC/ratter/tree/main/Protocols">Browse All Protocols</a></li>
        </ul>
    </div>
</div>

<div class="quick-start">
    <h2>🤝 Development and Contribution</h2>
    <p><strong>BControl</strong> is built on legacy MATLAB code and maintained through incremental patches and continuous development. For detailed development instructions, check the <a href="https://github.com/LIMLabSWC/ratter">GitHub page</a>.</p>
</div>

<style>
.intro-section {
    background: white;
    border: 1px solid #e1e8ed;
    border-radius: 6px;
    padding: 2rem;
    margin: 2rem 0;
    border-left: 4px solid #3498db;
}

.intro-section h2 {
    color: #2c3e50;
    margin-bottom: 1rem;
    font-size: 1.4rem;
    font-weight: 600;
}

.intro-section p {
    color: #555;
    line-height: 1.6;
    margin: 0;
}

.nav-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 1.5rem;
    margin-bottom: 3rem;
}

.nav-card {
    background: white;
    border: 1px solid #e1e8ed;
    border-radius: 6px;
    padding: 1.5rem;
    transition: border-color 0.2s ease;
    border-left: 4px solid #3498db;
    min-height: 200px;
    display: flex;
    flex-direction: column;
}

.nav-card:hover {
    border-color: #3498db;
}

.nav-card h3 {
    color: #2c3e50;
    margin-bottom: 1rem;
    font-size: 1.2rem;
    font-weight: 600;
}

.nav-card ul {
    list-style: none;
}

.nav-card li {
    margin-bottom: 0.5rem;
}

.nav-card a {
    color: #555;
    text-decoration: none;
    padding: 0.25rem 0;
    display: block;
    border-radius: 4px;
    transition: all 0.2s ease;
}

.nav-card a:hover {
    color: #3498db;
    background-color: #f8f9fa;
}

.quick-start {
    background: white;
    border: 1px solid #e1e8ed;
    border-radius: 6px;
    padding: 2rem;
    margin-bottom: 2rem;
    border-left: 4px solid #27ae60;
}

.quick-start h2 {
    color: #2c3e50;
    margin-bottom: 1rem;
    font-size: 1.4rem;
    font-weight: 600;
}

@media (max-width: 768px) {
    .nav-grid {
        grid-template-columns: 1fr;
    }
    
    .nav-card {
        min-height: auto;
    }
}
</style>
