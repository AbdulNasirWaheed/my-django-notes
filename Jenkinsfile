pipeline {
    agent any

    stages {
        stage('Clone the Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/AbdulNasirWaheed/my-django-notes'
            }
        }

        stage('Create Virtual Environment') {
            steps {
                sh 'python3 -m venv django'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    . django/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    pip install "setuptools<81"
                '''
            }
        }

        stage('Run Migrations') {
            steps {
                sh '''
                    . django/bin/activate
                    python manage.py makemigrations
                    python manage.py migrate
                '''
            }
        }

        stage('Collect Static Files') {
            steps {
                sh '''
                    . django/bin/activate
                    python manage.py collectstatic --noinput
                '''
            }
        }

        stage('Run Django App') {
            steps {
                sh '''
                    fuser -k 8000/tcp || true
                    . django/bin/activate
                    BUILD_ID=dontKillMe JENKINS_NODE_COOKIE=dontKillMe nohup gunicorn notesapp.wsgi:application --bind 0.0.0.0:8000 --workers 3 > server.log 2>&1 &
                    sleep 2
                    echo "Server started, checking it's alive:"
                    sudo ss -tulnp | grep 8000 || echo "WARNING: nothing listening on 8000"
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully. Django app is running on port 8000.'
        }
        failure {
            echo 'Pipeline failed. Check the stage logs above for details.'
        }
    }
}
