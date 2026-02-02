package com.example.login;

import java.io.IOException;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@WebServlet({"/history", "/recordHistory"})
public class HistoryServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String servletPath = request.getServletPath();
        HttpSession session = request.getSession();

        // 1. Logic to record a new history item
        if ("/recordHistory".equals(servletPath)) {
            String filePath = request.getParameter("path");
            String fileName = request.getParameter("name");

            if (filePath != null && fileName != null) {
                List<HistoryItem> history = (List<HistoryItem>) session.getAttribute("userHistory");
                if (history == null) {
                    history = new ArrayList<>();
                }
                
                // Add new item to the top of the list
                history.add(0, new HistoryItem(fileName, filePath));
                
                // Optional: Limit history to last 20 items
                if (history.size() > 20) history.remove(history.size() - 1);
                
                session.setAttribute("userHistory", history);
            }
            return; // Just recording, no need to redirect
        }

        // 2. Logic to display history
        request.getRequestDispatcher("history.jsp").forward(request, response);
    }

    // Helper class to store history data
    public static class HistoryItem {
        private String name;
        private String path;
        public HistoryItem(String name, String path) { this.name = name; this.path = path; }
        public String getName() { return name; }
        public String getPath() { return path; }
    }
}