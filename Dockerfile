# ใช้ Web Server ขนาดเล็กชื่อ Nginx เป็นตัวจำลองโฮสต์
FROM nginx:alpine

# ก๊อปปี้ไฟล์เว็บที่เราเพิ่ง Build เสร็จ เอาไปวางใน Server
COPY build/web /usr/share/nginx/html

# เปิดประตูพอร์ต 80 ให้คนอื่นเข้ามาดูเว็บได้
EXPOSE 80

# สั่งให้ Server ทำงานตลอดเวลา
CMD ["nginx", "-g", "daemon off;"]