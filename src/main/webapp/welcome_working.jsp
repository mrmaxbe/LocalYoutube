<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.io.File, java.net.URLEncoder" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>AmoebaTube | Time Capsule</title>
    <style>
        :root { --yt-black: #0f0f0f; --yt-card: #1e1e1e; --yt-red: #ff0000; --yt-text: #ffffff; --yt-gray: #aaaaaa; }
        body { font-family: "Roboto", Arial, sans-serif; background-color: var(--yt-black); color: var(--yt-text); margin: 0; display: flex; flex-direction: column; height: 100vh; }
        header { background-color: var(--yt-black); padding: 10px 20px; display: flex; align-items: center; justify-content: space-between; position: sticky; top: 0; z-index: 100; }
        .logo { color: var(--yt-text); font-size: 20px; font-weight: bold; display: flex; align-items: center; text-decoration: none; }
        .logo span { background-color: var(--yt-red); color: white; padding: 2px 6px; border-radius: 4px; margin-right: 5px; }
        .main-container { display: flex; flex: 1; overflow: hidden; }
        aside { width: 240px; padding: 15px; background-color: var(--yt-black); border-right: 1px solid #333; overflow-y: auto; }
        .nav-item { padding: 10px; border-radius: 8px; display: block; color: var(--yt-text); text-decoration: none; margin-bottom: 5px; }
        .nav-item:hover { background-color: #272727; }
        main { flex: 1; padding: 24px; overflow-y: auto; }
        .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 20px; }
        .card { background-color: transparent; border-radius: 12px; overflow: hidden; }
        .thumbnail-container { width: 100%; aspect-ratio: 16 / 9; background-color: #2a2a2a; border-radius: 12px; overflow: hidden; display: flex; flex-direction: column; align-items: center; justify-content: center; }
        .thumbnail-container img, .thumbnail-container video { width: 100%; height: 100%; object-fit: cover; }
        .folder-thumb { font-size: 50px; }
        .card-info { padding: 12px 0; }
        .card-title { font-size: 16px; font-weight: 500; margin-bottom: 4px; color: var(--yt-text); display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
        .card-meta { font-size: 14px; color: var(--yt-gray); }
        a { text-decoration: none; }
        audio { width: 90%; height: 35px; }
    </style>
</head>
<body>
    <header>
        <a href="home" class="logo"><span>Amoeba</span>Tube</a>
        <div style="color:var(--yt-gray)">Welcome, ${sessionScope.user}</div>
        <a href="login.jsp" style="color:var(--yt-gray); font-size: 14px;">Logout</a>
    </header>

    <div class="main-container">
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
        %>

        <aside>
            <a href="home" class="nav-item">🏠 Home</a>
            <hr style="border:0; border-top:1px solid #333; margin:10px 0;">
            <p style="padding-left:10px; font-size:12px; color:var(--yt-gray);">CURRENT FOLDER</p>
            <% if (!currentPath.equals(rootPath)) { %>
                <a class="nav-item" href="home?path=<%= URLEncoder.encode(currentFolder.getParent(), "UTF-8") %>">⬅️ Back One Level</a>
            <% } %>
            <div style="padding: 10px; font-size: 12px; color: #444; word-break: break-all;"><%= currentPath %></div>
        </aside>

        <main>
            <div class="grid">
                <%
                    if (files != null) {
                        for (File f : files) {
                            if (f.isHidden() || f.getName().startsWith(".")) continue;
                            String name = f.getName();
                            String encodedPath = URLEncoder.encode(f.getAbsolutePath(), "UTF-8");
                            String lowerName = name.toLowerCase();
                            if (f.isDirectory()) {
                %>
                                <div class="card">
                                    <a href="home?path=<%= encodedPath %>">
                                        <div class="thumbnail-container"><span class="folder-thumb">📁</span></div>
                                        <div class="card-info">
                                            <div class="card-title"><%= name %></div>
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
                                            <a href="displayFile?path=<%= encodedPath %>" target="_blank"><img src="displayFile?path=<%= encodedPath %>"></a>
                                        <% } else if (lowerName.endsWith(".mp4") || lowerName.endsWith(".mov")) { %>
                                            <video controls><source src="displayFile?path=<%= encodedPath %>" type="video/mp4"></video>
                                        <% } else if (lowerName.endsWith(".mp3")) { %>
                                            <span style="font-size:40px; margin-bottom: 10px;">🎵</span>
                                            <audio controls><source src="displayFile?path=<%= encodedPath %>" type="audio/mpeg"></audio>
                                        <% } else { %>
                                            <a href="displayFile?path=<%= encodedPath %>" target="_blank"><span style="font-size:40px;">📄</span></a>
                                        <% } %>
                                    </div>
                                    <div class="card-info">
                                        <div class="card-title"><%= name %></div>
                                        <div class="card-meta">File • <%= (f.length() / 1024) %> KB</div>
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
</body>
</html>