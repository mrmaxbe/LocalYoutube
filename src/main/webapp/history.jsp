<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, HistoryServlet.HistoryItem" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>History - Time Travel</title>
    <style>
        :root { --yt-black: #0f0f0f; --yt-text: #ffffff; --yt-gray: #aaaaaa; }
        body { font-family: "Roboto", sans-serif; background-color: var(--yt-black); color: var(--yt-text); margin: 0; }
        header { padding: 10px 20px; border-bottom: 1px solid #333; display: flex; align-items: center; gap: 20px; }
        .nav-tab { color: var(--yt-text); text-decoration: none; font-weight: 500; padding: 8px 12px; border-radius: 8px; }
        .nav-tab:hover { background-color: rgba(255,255,255,0.1); }
        main { padding: 24px; max-width: 800px; margin: 0 auto; }
        .history-list { list-style: none; padding: 0; }
        .history-item { 
            display: flex; justify-content: space-between; padding: 15px; 
            border-bottom: 1px solid #222; transition: background 0.2s;
        }
        .history-item:hover { background: #1a1a1a; }
        .file-name { font-weight: 500; color: #3ea6ff; text-decoration: none; }
        .file-path { font-size: 12px; color: var(--yt-gray); margin-top: 4px; }
    </style>
</head>
<body>
    <header>
        <a href="home" class="nav-tab">← Back to Home</a>
        <h2>Watch History</h2>
    </header>
    <main>
        <ul class="history-list">
            <%
                List<HistoryItem> history = (List<HistoryItem>) session.getAttribute("userHistory");
                if (history == null || history.isEmpty()) {
            %>
                <p style="color: var(--yt-gray);">Your history is empty.</p>
            <%
                } else {
                    for (HistoryItem item : history) {
            %>
                <li class="history-item">
                    <div>
                        <a href="home?path=<%= item.getPath() %>" class="file-name"><%= item.getName() %></a>
                        <div class="file-path"><%= item.getPath() %></div>
                    </div>
                </li>
            <%
                    }
                }
            %>
        </ul>
    </main>
</body>
</html>