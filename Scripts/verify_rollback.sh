#!/bin/bash
# Aware Framework: Autonomous Rollback Verification
# Ensures that applying an 'up' migration and its corresponding 'down' rollback
# results in the exact same database state (hash matching).

set -e

DB_FILE=${1:-"test_db.sqlite"}
UP_MIGRATION=$2
DOWN_MIGRATION=$3

if [ -z "$UP_MIGRATION" ] || [ -z "$DOWN_MIGRATION" ]; then
    echo "Usage: $0 <db_file> <up.sql> <down.sql>"
    exit 1
fi

echo "🔍 Running Aware Rollback Verification..."

# 1. Capture Pre-Migration State Hash
PRE_HASH=$(sqlite3 "$DB_FILE" ".schema" | shasum -a 256 | awk '{print $1}')
echo "   Pre-Up Hash:   $PRE_HASH"

# 2. Apply UP Migration
echo "⬆️  Applying UP migration: $UP_MIGRATION"
sqlite3 "$DB_FILE" < "$UP_MIGRATION"

# 3. Apply DOWN Migration
echo "⬇️  Applying DOWN rollback: $DOWN_MIGRATION"
sqlite3 "$DB_FILE" < "$DOWN_MIGRATION"

# 4. Capture Post-Rollback State Hash
POST_HASH=$(sqlite3 "$DB_FILE" ".schema" | shasum -a 256 | awk '{print $1}')
echo "   Post-Down Hash: $POST_HASH"

# 5. Assert Equality
if [ "$PRE_HASH" == "$POST_HASH" ]; then
    echo "✅ Success: Rollback hash perfectly matches the initial state."
    exit 0
else
    echo "❌ Error: Rollback hash mismatch!"
    echo "   The DOWN migration did not cleanly revert the UP migration."
    exit 1
fi
