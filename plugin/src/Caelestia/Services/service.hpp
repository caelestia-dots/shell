
    void unref(QObject* sender);

private:
    QSet<QObject*> m_refs;

    virtual void start() = 0;
    virtual void stop() = 0;
};

} // namespace caelestia::services
