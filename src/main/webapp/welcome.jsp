<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.File, java.net.URLEncoder, java.util.ArrayList, java.util.List, java.util.Arrays, java.util.Comparator" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Thendral's Time Travel</title>
    <style>
        :root { 
            --yt-black: #0f0f0f;
            --yt-card: #1e1e1e; 
            --yt-red: #ff0000; 
            --yt-text: #ffffff; 
            --yt-gray: #aaaaaa; 
        }
        
        body { 
            font-family: "Roboto", "Arial", sans-serif;
            background-color: var(--yt-black); 
            color: var(--yt-text); 
            margin: 0; 
            display: flex; 
            flex-direction: column; 
            height: 100vh; 
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
        }
        
        header { 
            background-color: var(--yt-black);
            padding: 10px 20px; 
            display: flex; 
            align-items: center; 
            gap: 20px;
            position: sticky; 
            top: 0; 
            z-index: 100; 
            border-bottom: 1px solid #333;
        }
        
        .logo { 
            color: var(--yt-text);
            font-size: 20px; 
            font-weight: bold; 
            display: flex; 
            align-items: center; 
            text-decoration: none; 
            min-width: fit-content; 
            letter-spacing: -0.5px;
        }

        .logo svg {
            width: 32px;
            height: 32px;
            margin-right: 6px;
        }

        /* Added Styles for History Tabs */
        .header-tabs {
            display: flex;
            gap: 15px;
            margin-left: 20px;
        }

        .nav-tab {
            color: var(--yt-text);
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            padding: 8px 12px;
            border-radius: 8px;
            transition: background 0.2s;
        }

        .nav-tab:hover {
            background-color: rgba(255, 255, 255, 0.1);
        }
        
        .current-path {
            color: var(--yt-gray);
            font-size: 14px; 
            background: #272727; 
            padding: 5px 12px; 
            border-radius: 20px;
            white-space: nowrap; 
            overflow: hidden; 
            text-overflow: ellipsis; 
            max-width: 300px;
        }

        .header-right { margin-left: auto; display: flex; align-items: center; gap: 15px; }
        .main-container { display: flex; flex: 1; overflow: hidden; }
        main { flex: 1; padding: 24px; overflow-y: auto; }
        
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; }
        .card { background-color: transparent; border-radius: 12px; overflow: hidden; transition: transform 0.2s; }
        .card:hover { transform: scale(1.02); }
        .card a { text-decoration: none; color: inherit; display: block; }
        
        .thumbnail-container { 
            width: 100%; aspect-ratio: 16 / 9; background-color: #2a2a2a; border-radius: 12px; 
            overflow: hidden; display: flex; flex-direction: column; align-items: center; 
            justify-content: center; cursor: pointer; position: relative;
        }
        .thumbnail-container img { width: 100%; height: 100%; object-fit: cover; }
        .folder-thumb { font-size: 50px; }
        
        .card-info { padding: 12px 0; }
        
        .card-title { 
            font-size: 16px; font-weight: 500; line-height: 1.4rem; max-height: 2.8rem;
            overflow: hidden; display: -webkit-box; -webkit-line-clamp: 2; 
            -webkit-box-orient: vertical; margin-bottom: 4px; color: var(--yt-text);
        }
        
        .card-meta { font-size: 14px; font-weight: 400; color: var(--yt-gray); }
        
        .play-overlay { position: absolute; font-size: 40px; color: white; opacity: 0.7; pointer-events: none; top:50%; left:50%; transform:translate(-50%, -50%); }

        .modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.95); justify-content: center; align-items: center; }
        .close-btn { position: absolute; top: 20px; right: 35px; color: white; font-size: 40px; cursor: pointer; z-index: 1100; }
        #modalImg { max-width: 90%; max-height: 80%; border-radius: 4px; }
        .nav-arrow { position: absolute; top: 50%; color: white; font-size: 60px; cursor: pointer; user-select: none; transform: translateY(-50%); padding: 0 20px; }
        #modalVideo { max-width: 90%; max-height: 70vh; outline: none; }

        #videoTray { position: absolute; bottom: -160px; left: 0; width: 100%; height: 150px; background: rgba(15, 15, 15, 0.95); border-top: 1px solid #444; transition: bottom 0.3s ease; z-index: 1020; }
        #videoTray.open { bottom: 0; }
        #trayHandle { position: absolute; top: -40px; left: 50%; transform: translateX(-50%); background: rgba(30,30,30,0.9); padding: 5px 25px; border-radius: 10px 10px 0 0; cursor: pointer; color: white; display: none; }
        .tray-content { display: flex; overflow-x: auto; gap: 15px; padding: 15px; }
        .tray-item { min-width: 140px; cursor: pointer; text-align: center; color: white; }
        .tray-item img { width: 100%; border-radius: 5px; }
        .tray-item-title { font-size: 12px; font-weight: 400; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-top: 4px; }
        
        .back-btn { color: white; background: #333; padding: 5px 15px; border-radius: 4px; font-size: 14px; text-decoration: none; }
        audio { width: 90%; height: 35px; }
    </style>

    <script>
        let currentImgIndex = 0;
        let images = [];

        function openModal(imgSrc, imgName) {
            const allImgElements = Array.from(document.querySelectorAll('.img-trigger'));
            images = allImgElements.map(el => ({ 
                src: el.getAttribute('data-src'), 
                name: el.getAttribute('data-name') 
            }));
            currentImgIndex = images.findIndex(img => img.src === imgSrc);
            updateModalContent();
            document.getElementById("photoModal").style.display = "flex";
        }

        function updateModalContent() {
            document.getElementById("modalImg").src = images[currentImgIndex].src;
        }

        function changePhoto(n) {
            currentImgIndex = (currentImgIndex + n + images.length) % images.length;
            updateModalContent();
        }

        function closeModal() { document.getElementById("photoModal").style.display = "none"; }

        function openVideoModal(videoSrc) {
            const modal = document.getElementById("videoModal");
            const video = document.getElementById("modalVideo");
            video.src = videoSrc;
            modal.style.display = "flex";
            video.play();
        }

        function closeVideoModal() {
            const modal = document.getElementById("videoModal");
            const video = document.getElementById("modalVideo");
            video.pause();
            video.src = "";
            modal.style.display = "none";
            document.getElementById("videoTray").classList.remove("open");
        }

        function toggleTray() {
            const tray = document.getElementById("videoTray");
            const handle = document.getElementById("trayHandle");
            if (tray.classList.contains("open")) {
                tray.classList.remove("open");
                handle.innerHTML = "▲";
            } else {
                tray.classList.add("open");
                handle.innerHTML = "▼";
            }
        }

        // Added Function for History Tracking
        function logHistory(name, path) {
            fetch('recordHistory?name=' + encodeURIComponent(name) + '&path=' + encodeURIComponent(path));
        }

        window.onclick = function(event) { 
            if (event.target.id == "photoModal") closeModal();
            if (event.target.id == "videoModal") closeVideoModal();
        }

        document.addEventListener('mousemove', function(e) {
            const handle = document.getElementById("trayHandle");
            const modal = document.getElementById("videoModal");
            if (modal.style.display === "flex") {
                if (window.innerHeight - e.clientY < 80) handle.style.display = "block";
                else if (!document.getElementById("videoTray").classList.contains("open")) handle.style.display = "none";
            }
        });

        document.onkeydown = function(evt) {
            if (document.getElementById("photoModal").style.display === "flex") {
                if (evt.key === "Escape") closeModal();
                if (evt.key === "ArrowRight") changePhoto(1);
                if (evt.key === "ArrowLeft") changePhoto(-1);
            }
            if (document.getElementById("videoModal").style.display === "flex") {
                if (evt.key === "Escape") closeVideoModal();
            }
        };
    </script>
</head>
<body>

    <%
        String rootPath = "/Volumes/Data";
        String subPath = request.getParameter("path");
        String currentPath = (subPath == null || subPath.isEmpty()) ? rootPath : subPath;
        File currentFolder = new File(currentPath);
        if (!currentFolder.exists() || !currentFolder.getAbsolutePath().startsWith(rootPath)) {
            currentPath = rootPath;
            currentFolder = new File(rootPath);
        }
        File[] files = currentFolder.listFiles();
        List<File> videoList = new ArrayList<>();

        // Sorting Logic: Sort by last modified date (Newest First)
        if (files != null) {
            Arrays.sort(files, new Comparator<File>() {
                public int compare(File f1, File f2) {
                    return Long.compare(f2.lastModified(), f1.lastModified());
                }
            });
        }
    %>

    <header>
        <a href="home" class="logo">
            <svg viewBox="0 0 24 24" preserveAspectRatio="xMidYMid meet" focusable="false">
                <g>
                    <path d="M23.49 6.75c-.27-1-.48-1.21-1.48-1.48C20.01 5 12 5 12 5s-8 0-10.01.27c-1 .27-1.21.48-1.48 1.48C0 8.76 0 12 0 12s0 3.24.51 5.25c.27 1 .48 1.21 1.48 1.48C4 19 12 19 12 19s8 0 10.01-.27c1-.27 1.21-.48 1.48-1.48.51-2.01.51-5.25.51-5.25s0-3.24-.51-5.25z" fill="#FF0000"></path>
                    <path d="M9.5 15.5l6.5-3.5-6.5-3.5z" fill="#ffffff"></path>
                </g>
            </svg>
            Thendral's Time Travel
        </a>
        
        <div class="header-tabs">
            <a href="home" class="nav-tab">Home</a>
            <a href="history" class="nav-tab">History</a>
        </div>

        <div class="current-path">📂 <%= currentPath %></div>
        <% if (!currentPath.equals(rootPath)) { %>
            <a href="home?path=<%= URLEncoder.encode(currentFolder.getParent(), "UTF-8") %>" class="back-btn">⬅ Back</a>
        <% } %>
        <div class="header-right">
            <div style="color:var(--yt-gray); font-size: 14px;">Hi, ${sessionScope.user}</div>
            <a href="login.jsp" style="color:var(--yt-red); text-decoration: none; font-weight: bold;">Logout</a>
        </div>
    </header>

    <div class="main-container">
        <main>
            <div class="grid">
                <%
                    if (files != null) {
                        for (File f : files) {
                            if (f.isHidden() || f.getName().startsWith(".")) continue;
                            String fullName = f.getName();
                            String lowerName = fullName.toLowerCase();
                            String encodedPath = URLEncoder.encode(f.getAbsolutePath(), "UTF-8");
                            String displayName = fullName.contains(".") ? fullName.substring(0, fullName.lastIndexOf(".")) : fullName;
                            
                            if (f.isDirectory()) {
                %>
                                <div class="card">
                                    <a href="home?path=<%= encodedPath %>">
                                        <div class="thumbnail-container">
                                            <span class="folder-thumb">📁</span>
                                        </div>
                                        <div class="card-info">
                                            <div class="card-title"><%= displayName %></div>
                                            <div class="card-meta">Folder</div>
                                        </div>
                                    </a>
                                </div>
                <%
                            } else {
                %>
                                <div class="card">
                                    <div class="thumbnail-container">
                                        <% if (lowerName.endsWith(".jpg") || lowerName.endsWith(".jpeg") || lowerName.endsWith(".png")) { %>
                                            <div class="img-trigger" 
                                                 data-src="displayFile?path=<%= encodedPath %>"
                                                 data-name="<%= displayName %>" 
                                                 onclick="logHistory('<%= displayName %>', '<%= encodedPath %>'); openModal('displayFile?path=<%= encodedPath %>', '<%= displayName %>')">
                                                <img src="displayFile?path=<%= encodedPath %>">
                                            </div>
                                        <% } else if (lowerName.endsWith(".mp4") || lowerName.endsWith(".mov") || lowerName.endsWith(".mkv")) { 
                                            videoList.add(f);
                                            String thumbUrl = "displayFile?path=" + encodedPath + "&type=thumb";
                                        %>
                                            <div style="width:100%; height:100%;"
                                                 onclick="logHistory('<%= displayName %>', '<%= encodedPath %>'); openVideoModal('displayFile?path=<%= encodedPath %>')">
                                                <img src="<%= thumbUrl %>">
                                                <div class="play-overlay">▶</div>
                                            </div>
                                        <% } else if (lowerName.endsWith(".mp3")) { %>
                                            <span style="font-size:40px; margin-bottom: 10px;">🎵</span>
                                            <audio controls onplay="logHistory('<%= displayName %>', '<%= encodedPath %>')">
                                                <source src="displayFile?path=<%= encodedPath %>" type="audio/mpeg">
                                            </audio>
                                        <% } else { %>
                                            <a href="displayFile?path=<%= encodedPath %>" target="_blank" onclick="logHistory('<%= displayName %>', '<%= encodedPath %>')">
                                                <span style="font-size:40px;">📄</span>
                                            </a>
                                        <% } %>
                                    </div>
                                    <div class="card-info">
                                        <div class="card-title"><%= displayName %></div>
                                        <div class="card-meta">File • <%= (f.length() / 1024 / 1024) %> MB</div>
                                    </div>
                                </div>
                <%
                            }
                        }
                    }
                %>
            </div>
        </main>
    </div>

    <div id="photoModal" class="modal">
        <span class="close-btn" onclick="closeModal()">&times;</span>
        <img id="modalImg" src="">
        <a class="nav-arrow" style="left: 2%;" onclick="changePhoto(-1)">&#10094;</a>
        <a class="nav-arrow" style="right: 2%;" onclick="changePhoto(1)">&#10095;</a>
    </div>

    <div id="videoModal" class="modal">
        <span class="close-btn" onclick="closeVideoModal()">&times;</span>
        <video id="modalVideo" controls></video>

        <div id="videoTray">
            <div id="trayHandle" onclick="toggleTray()">▲</div>
            <div class="tray-content">
                <% for (File v : videoList) { 
                    String vPath = URLEncoder.encode(v.getAbsolutePath(), "UTF-8");
                    String vFullName = v.getName();
                    String vDisplayName = vFullName.contains(".") ? vFullName.substring(0, vFullName.lastIndexOf(".")) : vFullName;
                %>
                    <div class="tray-item" onclick="logHistory('<%= vDisplayName %>', '<%= vPath %>'); openVideoModal('displayFile?path=<%= vPath %>')">
                        <img src="displayFile?path=<%= vPath %>&type=thumb">
                        <div class="tray-item-title"><%= vDisplayName %></div>
                    </div>
                <% } %>
            </div>
        </div>
    </div>
</body>
</html>