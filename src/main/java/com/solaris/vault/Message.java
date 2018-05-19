package com.solaris.vault;

import lombok.AccessLevel;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import javax.persistence.*;
import java.util.Date;

@Entity
@Data
@NoArgsConstructor
public class Message {
    @Id
    @Setter(AccessLevel.NONE)
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", insertable = false)
    private Long id;

    @Column(name = "message", nullable = false)
    private String message;

    @Temporal(TemporalType.TIMESTAMP)
    @GeneratedValue
    @CreationTimestamp
    @Column(name = "created", length = 200, nullable = false)
    private Date created;
}
