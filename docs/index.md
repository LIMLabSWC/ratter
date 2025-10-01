---
title: BControl Documentation
layout: default
---

<div class="intro-section">
    <h2>About BControl</h2>
    <p><strong>BControl</strong> is a behavioral experimentation system that provides a flexible and extensible framework for running behavioral protocols. Designed to support a variety of experiments with user-friendly configuration and robust MATLAB-based components, BControl serves as the core platform for our high-throughput behavior training facility. The system enables researchers to design, implement, and execute complex behavioral experiments with precise control over experimental parameters, data collection, and protocol management.</p>
</div>

<div class="warning-banner">
    <h3>⚠️ Recent Changes (May 2025)</h3>
    <p>We are undergoing a major modernization effort. Please see the <a href="{{ '/recent-refactoring/README' | relative_url }}">Recent Refactoring Overview</a> for details, including:</p>
    <ul style="margin-top: 0.5rem; margin-left: 1.5rem;">
        <li>Removal of legacy Perl scripts</li>
        <li>Protocol directory restructuring</li>
        <li>Documentation modernization</li>
        <li>ExperPort cleanup and optimization</li>
        <li>Current testing status and next steps</li>
    </ul>
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

.warning-banner {
    background: #f8f9fa;
    border: 1px solid #e9ecef;
    border-left: 4px solid #f39c12;
    border-radius: 4px;
    padding: 1rem;
    margin: 2rem 0;
    color: #2c3e50;
}

.warning-banner h3 {
    color: #e67e22;
    margin-bottom: 0.5rem;
    font-size: 1.1rem;
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
