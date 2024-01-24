import bcrypt
import base64
print(base64.b64encode(bcrypt.hashpw("udaanpro379".encode("utf-8"), bcrypt.gensalt(6))))