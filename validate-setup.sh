#!/bin/bash

echo "🔍 Validating Quarkus OIDC Redis NPE Reproduction Setup"
echo "======================================================="

# Check if required tools are available
echo "📋 Checking prerequisites..."

# Check Java
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1)
    echo "✅ Java found: $JAVA_VERSION"
else
    echo "❌ Java not found. Please install Java 17+"
    exit 1
fi

# Check Maven
if command -v mvn &> /dev/null; then
    MVN_VERSION=$(mvn -version | head -n 1)
    echo "✅ Maven found: $MVN_VERSION"
else
    echo "❌ Maven not found. Please install Maven 3.8+"
    exit 1
fi

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    echo "✅ Docker found: $DOCKER_VERSION"
else
    echo "❌ Docker not found. Please install Docker"
    exit 1
fi

echo ""
echo "📁 Checking project structure..."

# Check required files
REQUIRED_FILES=(
    "pom.xml"
    "src/main/java/org/acme/GreetingResource.java"
    "src/main/resources/application.properties"
    "README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

echo ""
echo "🔧 Checking configuration..."

# Check if placeholders are still in place
if grep -q "<YOUR_GOOGLE_CLIENT_ID>" src/main/resources/application.properties; then
    echo "⚠️  Google Client ID placeholder found - please configure your credentials"
else
    echo "✅ Google Client ID configured"
fi

if grep -q "<YOUR_GOOGLE_CLIENT_SECRET>" src/main/resources/application.properties; then
    echo "⚠️  Google Client Secret placeholder found - please configure your credentials"
else
    echo "✅ Google Client Secret configured"
fi

echo ""
echo "🚀 Quick start commands:"
echo "1. Start Redis: docker run --rm --name my-redis -p 6379:6379 redis:7"
echo "2. Configure credentials in: src/main/resources/application.properties"
echo "3. Run application: ./mvnw quarkus:dev"
echo "4. Test endpoint: http://localhost:8080/hello"

echo ""
echo "✨ Setup validation complete!"
