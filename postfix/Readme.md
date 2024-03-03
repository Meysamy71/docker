## Send mail in docker postfix

---

### Change to .env file

---

### Change to main.cf file ----> relayhost = [smtp.gmail.com]:587

---

`docker compose up -d`

---

`docker exec -it smtp-server /bin/bash -c 'echo "Test email body" | mail -s "Test email subject" TO_EMAIL'`
