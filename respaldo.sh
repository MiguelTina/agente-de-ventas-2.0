#!/bin/bash

echo "🚀 Iniciando respaldo del proyecto..."

# Verifica si hay cambios
if git diff --quiet && git diff --cached --quiet; then
    echo "✅ No hay cambios nuevos para respaldar."
    exit 0
fi

# Agrega todo al commit
git add .

# Pide mensaje del commit
echo "📝 Escribe el mensaje para el respaldo:"
read mensaje

# Realiza el commit
git commit -m "$mensaje"

# Sube a GitHub
git push origin main

echo "✅ Respaldo completado correctamente."
