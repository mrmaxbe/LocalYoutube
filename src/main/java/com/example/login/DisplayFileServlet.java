package com.example.login;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.URLDecoder;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class DisplayFileServlet extends HttpServlet {
    
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        String filePath = request.getParameter("path");
        String type = request.getParameter("type"); 
        if (filePath == null) return;

        filePath = URLDecoder.decode(filePath, "UTF-8");
        File file = new File(filePath);

        if (!file.exists()) {
            response.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        // --- THUMBNAIL LOGIC ---
        if ("thumb".equals(type)) {
            handleThumbnailRequest(file, response);
            return;
        }

        // --- STANDARD STREAMING LOGIC ---
        String name = file.getName().toLowerCase();
        String contentType = getServletContext().getMimeType(name);
        
        if (name.endsWith(".mp3")) contentType = "audio/mpeg";
        else if (name.endsWith(".mov")) contentType = "video/quicktime";
        else if (name.endsWith(".mp4")) contentType = "video/mp4";
        else if (name.endsWith(".mkv")) contentType = "video/x-matroska";

        String range = request.getHeader("Range");
        if (range == null) {
            response.setContentType(contentType != null ? contentType : "application/octet-stream");
            response.setContentLengthLong(file.length());
            response.setHeader("Accept-Ranges", "bytes");
            streamFile(file, response.getOutputStream());
        } else {
            handleRangeRequest(file, range, contentType, response);
        }
    }

    private void handleThumbnailRequest(File videoFile, HttpServletResponse response) throws IOException {
        // 1. First, look for a matching image file in the same folder (Your specific request)
        String fileName = videoFile.getName();
        int dotIndex = fileName.lastIndexOf(".");
        String baseName = (dotIndex == -1) ? fileName : fileName.substring(0, dotIndex);
        
        File parentDir = videoFile.getParentFile();
        String[] imgExts = {".jpg", ".jpeg", ".png", ".JPG", ".PNG"};
        File sourceThumb = null;

        for (String ext : imgExts) {
            File check = new File(parentDir, baseName + ext);
            if (check.exists()) {
                sourceThumb = check;
                break;
            }
        }

        if (sourceThumb != null) {
            response.setContentType(sourceThumb.getName().toLowerCase().endsWith(".png") ? "image/png" : "image/jpeg");
            streamFile(sourceThumb, response.getOutputStream());
            return;
        }

        // 2. If no image exists, generate one using FFMPEG with the ABSOLUTE PATH
        generateFfmpegThumbnail(videoFile, response);
    }

    private void generateFfmpegThumbnail(File videoFile, HttpServletResponse response) throws IOException {
        String tmpDir = System.getProperty("java.io.tmpdir");
        String thumbName = "cache_thumb_" + Math.abs(videoFile.getAbsolutePath().hashCode()) + ".jpg";
        File cacheFile = new File(tmpDir, thumbName);

        if (!cacheFile.exists()) {
            try {
                // FIXED: Using your specific Mac Homebrew path
                ProcessBuilder pb = new ProcessBuilder(
                    "/opt/homebrew/bin/ffmpeg", 
                    "-y", 
                    "-ss", "00:00:02", 
                    "-i", videoFile.getAbsolutePath(), 
                    "-vframes", "1", 
                    "-s", "320x180", 
                    cacheFile.getAbsolutePath()
                );
                
                Process p = pb.start();
                p.waitFor();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        if (cacheFile.exists()) {
            response.setContentType("image/jpeg");
            streamFile(cacheFile, response.getOutputStream());
        } else {
            response.sendError(404);
        }
    }

    private void streamFile(File file, OutputStream os) throws IOException {
        try (FileInputStream is = new FileInputStream(file)) {
            byte[] buffer = new byte[65536];
            int read;
            while ((read = is.read(buffer)) != -1) {
                os.write(buffer, 0, read);
            }
        }
    }

    private void handleRangeRequest(File file, String range, String contentType, HttpServletResponse response) throws IOException {
        long length = file.length();
        String[] ranges = range.replace("bytes=", "").split("-");
        long start = Long.parseLong(ranges[0]);
        long end = ranges.length > 1 ? Long.parseLong(ranges[1]) : length - 1;

        response.setStatus(HttpServletResponse.SC_PARTIAL_CONTENT);
        response.setContentType(contentType);
        response.setHeader("Content-Range", "bytes " + start + "-" + end + "/" + length);
        response.setContentLengthLong(end - start + 1);

        try (java.io.RandomAccessFile raf = new java.io.RandomAccessFile(file, "r");
             OutputStream os = response.getOutputStream()) {
            raf.seek(start);
            byte[] buffer = new byte[65536];
            long toRead = end - start + 1;
            while (toRead > 0) {
                int len = (int) Math.min(buffer.length, toRead);
                int read = raf.read(buffer, 0, len);
                if (read == -1) break;
                os.write(buffer, 0, read);
                toRead -= read;
            }
        }
    }
}