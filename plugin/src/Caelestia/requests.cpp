#include "requests.hpp"

#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
#include <qjsvalueiterator.h>
#include <qnetworkcookiejar.h>

namespace caelestia {

Requests::Requests(QObject* parent)
    : QObject(parent)
    , m_manager(new QNetworkAccessManager(this)) {}

void Requests::get(const QUrl& url, QJSValue onSuccess, QJSValue onError, QJSValue headers) const {
    if (!onSuccess.isCallable()) {
        qWarning() << "Requests::get: onSuccess is not callable";
        return;
    }

    QNetworkRequest request(url);
    request.setAttribute(QNetworkRequest::CacheLoadControlAttribute, QNetworkRequest::AlwaysNetwork);
    request.setAttribute(QNetworkRequest::CookieSaveControlAttribute, QNetworkRequest::Manual);
    request.setRawHeader("Cache-Control", "no-cache, no-store");
    request.setRawHeader("Pragma", "no-cache");
    request.setRawHeader("Connection", "close");

    if (headers.isObject()) {
        QJSValueIterator it(headers);
        while (it.hasNext()) {
            it.next();
            request.setRawHeader(it.name().toUtf8(), it.value().toString().toUtf8());
        }
    }

    auto reply = m_manager->get(request);

    QObject::connect(reply, &QNetworkReply::finished, [reply, onSuccess, onError]() {
        if (reply->error() == QNetworkReply::NoError) {
            onSuccess.call({ QString(reply->readAll()) });
        } else if (onError.isCallable()) {
            onError.call({ reply->errorString() });
        } else {
            qWarning() << "Requests::get: request failed with error" << reply->errorString();
        }

        reply->deleteLater();
    });
}

void Requests::resetCookies() const {
    m_manager->setCookieJar(new QNetworkCookieJar(m_manager));
}

} // namespace caelestia
